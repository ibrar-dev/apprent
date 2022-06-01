defmodule AppCount.Public.Auth do
  alias AppCount.Core.ClientSchema

  @moduledoc """
  The Public context.
  """

  import Ecto.Query, warn: false
  alias AppCount.Repo
  import Ecto.Query

  alias AppCount.Admins.Admin
  alias AppCount.Public.User
  alias AppCount.Core.ClientSchema

  def authenticate_user(username, password) do
    from(
      u in User,
      preload: [:client],
      where: u.username == ^username
    )
    |> Repo.one(prefix: "public")
    |> case do
      nil ->
        {:error, :not_found}

      user ->
        case Bcrypt.verify_pass(password, user.password_hash) do
          true ->
            # correct credentials, login sequence should start

            # We need to load tenant related user information

            {
              :ok,
              get_tenant_data(
                user.type,
                ClientSchema.new(user.client.client_schema, Map.delete(user, :password_hash))
              )
            }

          false ->
            {:error, :not_found}
            # {:error, %{message: "Incorrect Password!"}}
        end
    end
  end

  @doc """
  Get Client Admin, Tenant, or Tech Account information
  BEFORE MODIFYING THE STRUCT THIS FUNCTION RETURNS YOU MUST MUST CLEAR IT WITH DAVID FIRST.
  MODIFYING THE STRUCT MAY CAUSE ALL LOGGED IN USERS TO SEE AN Internal Server Error
  """
  def get_tenant_data("Admin", %AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: user
      }) do
    admin =
      from(a in Admin,
        where: a.id == ^user.tenant_account_id,
        select: %{id: a.id, roles: a.roles, email: a.email, name: a.name}
      )
      |> Repo.one(prefix: client_schema)

    features =
      Repo.preload(user, [client: [client_modules: :module]], prefix: "public").client.client_modules
      |> Enum.into(%{}, &{:"#{&1.module.name}", &1.enabled})

    %AppCountAuth.Users.Admin{
      client_schema: client_schema,
      features: features,
      id: admin.id,
      roles: admin.roles,
      email: admin.email,
      name: admin.name,
      property_ids:
        AppCount.Admins.AccessServer.Loader.property_ids_for(
          ClientSchema.new(client_schema, admin)
        )
    }
  end

  # @doc """
  # Get Tenant  Account information
  # BEFORE MODIFYING THE STRUCT THIS FUNCTION RETURNS YOU MUST MUST CLEAR IT WITH DAVID FIRST.
  # MODIFYING THE STRUCT MAY CAUSE ALL LOGGED IN USERS TO SEE AN Internal Server Error
  # """
  def get_tenant_data("Tenant", %AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: user
      }) do
    account =
      from(
        t in AppCount.Tenants.Tenant,
        join: a in assoc(t, :account),
        join: p in assoc(a, :property),
        join: s in assoc(p, :setting),
        left_join: l in assoc(p, :logo_url),
        left_join: i in assoc(p, :icon_url),
        where: a.id == ^user.tenant_account_id,
        select:
          map(a, [
            :password_changed,
            :autopay,
            :receives_mailings,
            :uuid,
            :profile_pic,
            :preferred_language
          ]),
        select_merge:
          map(t, [:id, :email, :first_name, :last_name, :phone, :alarm_code, :payment_status]),
        select_merge: %{
          property: %{
            id: p.id,
            name: p.name,
            icon: i.url,
            logo: l.url
          }
        },
        select_merge: %{
          account_id: a.id,
          name: fragment("? || ' ' || ?", t.first_name, t.last_name),
          active: s.active
        }
      )
      |> Repo.one(prefix: client_schema)

    %AppCountAuth.Users.Tenant{
      tenant_account_id: user.tenant_account_id,
      client_schema: client_schema,
      user_id: user.id,
      property: account.property,
      password_changed: account.password_changed,
      autopay: account.autopay,
      receives_mailings: account.receives_mailings,
      uuid: account.uuid,
      profile_pic: account.profile_pic,
      preferred_language: account.preferred_language,
      id: account.id,
      email: account.email,
      first_name: account.first_name,
      last_name: account.last_name,
      phone: account.phone,
      alarm_code: account.alarm_code,
      payment_status: account.payment_status,
      account_id: account.account_id,
      name: account.name,
      active: account.active
    }
  end

  def get_tenant_data("AppRent", %AppCount.Core.ClientSchema{
        name: _client_schema,
        attrs: user
      }) do
    %AppCountAuth.Users.AppRent{
      id: user.id,
      username: user.username
    }
  end

  def get_tenant_data("Tech", %AppCount.Core.ClientSchema{
        name: _client_schema,
        attrs: _user
      }) do
    # {:ok, user}
  end

  def refresh_user(%AppCountAuth.Users.Admin{client_schema: c} = admin) do
    client = AppCount.Public.get_client_by_schema(c)
    params = [tenant_account_id: admin.id, type: "Admin", client_id: client.id]
    user = Repo.get_by(User, params, prefix: "public")
    get_tenant_data("Admin", ClientSchema.new(c, user))
  end

  def refresh_user(%AppCountAuth.Users.Tenant{client_schema: c} = admin) do
    client = AppCount.Public.get_client_by_schema(c)
    params = [tenant_account_id: admin.account_id, type: "Tenant", client_id: client.id]
    user = Repo.get_by(User, params, prefix: "public")
    get_tenant_data("Tenant", ClientSchema.new(c, user))
  end
end
