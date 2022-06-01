defmodule AppCount.Accounts.Utils.Accounts do
  alias AppCount.Repo
  alias AppCount.Tenants.TenantRepo
  alias AppCount.Tenants.TenancyRepo
  alias AppCount.Accounts.Account
  alias AppCount.Accounts.Login
  alias AppCount.Tenants.Tenant
  alias AppCount.Tenants.Utils.Tenants
  alias AppCount.Accounts.PasswordResetRepo
  alias AppCount.Accounts.LockRepo
  import Ecto.Query
  import AppCount.EctoExtensions
  alias AppCount.Core.ClientSchema

  def create_tenant_account(list_of_tenants) when is_list(list_of_tenants) do
    Enum.map(list_of_tenants, fn tenant -> create_tenant_account(tenant.id) end)
  end

  def create_tenant_account(tenant_id) do
    create_tenant_account(tenant_id, Tenants.property_for(tenant_id))
  end

  def create_tenant_account(_, nil), do: {:error, "Tenant has no current lease"}

  def create_tenant_account(tenant_id, property) do
    pwd = random_password()
    u_name = username(tenant_id)

    %Account{}
    |> Account.changeset(%{
      username: u_name,
      tenant_id: tenant_id,
      password: pwd,
      property_id: property.id
    })
    |> Repo.insert()
    |> case do
      {:ok, a} ->
        client = AppCount.Public.ClientRepo.from_schema(a.__meta__.prefix)

        %{
          tenant_account_id: a.id,
          type: "Tenant",
          client_id: client.id,
          username: a.username,
          password_hash: a.encrypted_password
        }
        |> AppCount.Public.Accounts.create_user()

        # TODO:SCHEMA
        AppCount.Tasks.Enqueue.enqueue(
          "New Tenant Account",
          &post_account_create/4,
          [
            tenant_id,
            u_name,
            pwd,
            property
          ],
          "dasmen"
        )

        {:ok, a}

      e ->
        e
    end
  end

  def post_account_create(tenant_id, u_name, pwd, property) do
    Repo.get(Tenant, tenant_id)
    |> AppCountCom.Accounts.account_created(u_name, pwd, property)
  end

  def set_language(account_id, language) do
    Repo.get(Account, account_id)
    |> Account.changeset(%{preferred_language: language})
    |> Repo.update()
  end

  def send_welcome_email(account_id) do
    account = Repo.get(Account, account_id)
    pwd = random_password()
    property = Tenants.property_for(account.tenant_id)

    account
    |> Account.changeset(%{password: pwd})
    |> Repo.update()
    |> case do
      {:ok, a} ->
        Repo.get(Tenant, a.tenant_id)
        |> AppCountCom.Accounts.account_created(a.username, pwd, property)

        {:ok, a}

      e ->
        e
    end
  end

  def username(tenant_id) do
    tenant = Repo.get(Tenant, tenant_id)
    AppCount.Public.Accounts.unique_username("#{tenant.first_name}#{tenant.last_name}", "Tenant")
  end

  def verify_tenant(%{
        "email" => email
      }) do
    from(
      t in Tenant,
      left_join: a in assoc(t, :account),
      where: ilike(t.email, ^"#{email}%"),
      select: %{
        id: t.id,
        account: a
      },
      limit: 1
    )
    |> Repo.one()
    |> verify_response(email)
  end

  defp verify_response(nil, _),
    do: {
      :error,
      "We are unable to find an apartment associated with your email address. Please try entering a different email or contact AppRent support for further assistance."
    }

  defp verify_response(
         %{
           id: id,
           account: account
         },
         _
       )
       when is_nil(account),
       do: create_tenant_account(id)

  defp verify_response(%{account: account}, _email) do
    AppCount.Accounts.Utils.Passwords.reset_password_request(account.username)
    |> case do
      {:ok, _} ->
        {:success, "A link to reset your password has been sent to the email address provided."}

      error ->
        error
    end
  end

  def update_account(%{account_id: account_id, id: tenant_id}, params) do
    acct = Repo.get(Account, account_id)

    acct
    |> Account.changeset(params)
    |> Repo.update()

    update_public_user(acct, params)

    Repo.get(Tenant, tenant_id)
    |> Tenant.changeset(
      Map.take(params, ~w/first_name last_name email phone alarm_code preferred_language/)
    )
    |> Repo.update()
  end

  def update_account(id, %{"password" => _, "admin_id" => admin_id} = params) do
    Repo.get(Account, id)
    |> Account.changeset(params)
    |> Repo.update()
    |> case do
      {:ok, acct} ->
        PasswordResetRepo.create(acct.id, admin_id)

        update_public_user(acct, params)

        {:ok, acct}

      error ->
        error
    end
  end

  def update_account(id, params) do
    account = Repo.get(Account, id)

    result =
      account
      |> Account.changeset(
        Map.take(
          params,
          ~w/receives_mailings password autopay allow_sms username preferred_language/
        )
      )
      |> Repo.update()

    update_public_user(account, params)

    # {:ok, %Account{}}
    result
  end

  def get_public_user(%Account{} = acct) do
    AppCount.Public.Accounts.get_user_by_account(acct)
  end

  def update_public_user(%Account{} = acct, params \\ %{}) do
    user = get_public_user(acct)

    case user do
      # No user exists (this should be very rare) - we create then update
      nil ->
        {:ok, user} = AppCount.Public.Accounts.create_user_from_account(acct)
        new_params = Map.take(params, ["username", "password"])
        AppCount.Public.Accounts.update_user(user, new_params)

      # A user exists! We update!
      _ ->
        new_params = Map.take(params, ["username", "password"])
        AppCount.Public.Accounts.update_user(user, new_params)
    end
  end

  def get_account(tenant_id) do
    sub =
      from(
        l in Login,
        select: map(l, [:id, :type, :account_id, :login_metadata]),
        select_merge: %{
          ts: fragment("EXTRACT(EPOCH FROM ?)", l.inserted_at)
        }
      )

    from(
      a in Account,
      left_join: l in assoc(a, :locks),
      left_join: pw_reset in assoc(a, :password_resets),
      left_join: pw_reset_admin in assoc(pw_reset, :admin),
      left_join: log in subquery(sub),
      on: log.account_id == a.id,
      left_join: admin in assoc(l, :admin),
      where: a.tenant_id == ^tenant_id,
      select:
        map(a, [:id, :autopay, :receives_mailings, :username, :allow_sms, :preferred_language]),
      select_merge: %{
        password_resets:
          jsonize(
            pw_reset,
            [
              :id,
              :inserted_at,
              {:admin_name, pw_reset_admin.name}
            ]
          ),
        locks:
          jsonize(
            l,
            [
              :id,
              :enabled,
              :reason,
              :comments,
              :inserted_at,
              :updated_at,
              {:admin, admin.name}
            ]
          ),
        logins: jsonize(log, [:id, :ts, :type, :login_metadata], log.ts, "DESC")
      },
      group_by: a.id
    )
    |> Repo.one()
  end

  def delete_account(%AppCount.Core.ClientSchema{name: client_schema, attrs: list_of_tenants})
      when is_list(list_of_tenants) do
    Enum.map(list_of_tenants, fn tenant ->
      delete_account(ClientSchema.new(client_schema, tenant.account.id))
    end)
  end

  def delete_account(%AppCount.Core.ClientSchema{name: client_schema, attrs: id}) do
    Repo.get(Account, id, prefix: client_schema)
    |> Repo.delete(prefix: client_schema)
  end

  def authenticate_account(_username, nil), do: false

  def authenticate_account(username, password) do
    from(
      t in Tenant,
      join: a in assoc(t, :account),
      where: a.username == ^username,
      select:
        map(
          a,
          [
            :encrypted_password,
            :password_changed,
            :autopay,
            :receives_mailings,
            :uuid,
            :preferred_language
          ]
        ),
      select_merge: map(t, [:id, :email, :first_name, :last_name, :phone]),
      select_merge: %{
        account_id: a.id
      }
    )
    |> Repo.all()
    |> Enum.reduce_while(
      false,
      fn acc, _ ->
        if Bcrypt.verify_pass(password, acc.encrypted_password) do
          {:halt, Map.delete(acc, :encrypted_password)}
        else
          {:cont, false}
        end
      end
    )
  end

  def get_property_id(uuid) do
    now = AppCount.current_time()

    from(
      t in Tenant,
      join: a in assoc(t, :account),
      join: te in assoc(t, :tenancies),
      join: u in assoc(te, :unit),
      join: p in assoc(u, :property),
      where: a.uuid == ^uuid,
      where: te.start_date <= ^now and is_nil(te.actual_move_out),
      select: p.id
    )
    |> Repo.one()
  end

  def unit_info(tenant_id) do
    tenancy = TenancyRepo.active_tenancy_for_tenant(tenant_id)

    if tenancy do
      from(
        u in AppCount.Properties.Unit,
        join: p in assoc(u, :property),
        left_join: logo in assoc(p, :logo_url),
        left_join: icon in assoc(p, :icon_url),
        where: u.id == ^tenancy.unit_id,
        select: %{
          unit: u.number,
          property: p.name,
          property_id: p.id,
          unit_id: u.id,
          address: u.address,
          logo: logo.url,
          icon: icon.url
        }
      )
      |> Repo.one()
    end
  end

  def account_lock(account_id) do
    LockRepo.account_lock(account_id)
  end

  def account_lock_exists?(account_id) do
    not is_nil(account_lock(account_id))
  end

  def check_if_user_registered(username) do
    from(
      a in Account,
      where: a.username == ^username,
      select: a.id
    )
    |> Repo.one()
  end

  defp random_password() do
    case AppCount.env(:environment) do
      :dev ->
        "password"

      :test ->
        "test_password"

      _ ->
        :crypto.strong_rand_bytes(5)
        |> Base.encode16()
    end
  end

  def reset_all_accounts(%AppCount.Core.ClientSchema{name: client_schema, attrs: property_id}) do
    tenants =
      TenantRepo.tenants_for_property([property_id])
      |> Repo.preload(:account)

    # Must also filter out all tenants t
    filtered_with_account = Enum.reject(tenants, fn x -> is_nil(x.account) end)

    _freshly_cleared_tenants =
      delete_account(ClientSchema.new(client_schema, filtered_with_account))

    TenantRepo.tenants_for_property([property_id])
    |> Enum.reject(fn tenant -> is_nil(tenant.email) end)
    |> Repo.preload(:account)
    |> create_tenant_account()
  end
end
