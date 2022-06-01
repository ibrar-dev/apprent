defmodule AppCount.Accounts.Utils.PaymentSources do
  alias AppCount.Repo
  alias AppCount.Settings
  alias AppCount.Accounts.PaymentSource
  import Ecto.Query

  @conversions %{
    "card_name" => :name,
    "account_name" => :name,
    "number" => :num1,
    "account_number" => :num1,
    "cvc" => :num2,
    "routing_number" => :num2,
    "exp" => :exp,
    "type" => :type,
    "brand" => :brand,
    "account_id" => :account_id,
    "last_4" => :last_4,
    "subtype" => :subtype,
    "is_default" => :is_default
  }

  # Get a payment source
  def get_payment_source(tenant_id, id) do
    from(
      payment_source in PaymentSource,
      join: account in assoc(payment_source, :account),
      where: account.tenant_id == ^tenant_id,
      where: payment_source.active,
      where: payment_source.id == ^id
    )
    |> Repo.one()
  end

  def get_default_payment_source(tenant_id) do
    from(
      payment_source in PaymentSource,
      join: account in assoc(payment_source, :account),
      where: account.tenant_id == ^tenant_id,
      where: payment_source.active,
      where: payment_source.is_default
    )
    |> Repo.one()
  end

  # Create payment source from CC token
  def create_payment_source(%{type: "cc"} = params) do
    %{tenant_id: tenant_id} = params

    with {:ok, processor} <- cc_processor_for_tenant(tenant_id),
         {:ok, response} <- Authorize.CreateCustomer.create_profile(processor, params) do
      params =
        params
        |> Map.merge(%{
          num1: response.authorize_profile_id,
          num2: response.authorize_payment_profile_id,
          is_tokenized: true,
          name: params.card_name,
          original_network_transaction_id: response.original_network_transaction_id,
          original_auth_amount_in_cents: response.original_auth_amount_in_cents
        })

      result =
        %PaymentSource{}
        |> PaymentSource.changeset(params)
        |> Repo.insert()

      case result do
        {:ok, payment_source} ->
          maybe_set_default_payment_source(payment_source.account_id)
          result

        {:error, _changeset} ->
          result
      end
    end
  end

  # Used only for bank accounts now
  def create_payment_source(params) do
    result =
      %PaymentSource{}
      |> PaymentSource.changeset(convert_params(params))
      |> Repo.insert()

    case result do
      {:ok, payment_source} ->
        maybe_set_default_payment_source(payment_source.account_id)
        result

      {:error, _changeset} ->
        result
    end
  end

  def maybe_set_default_payment_source(account_id) do
    sources = list_payment_sources_by_account(account_id)

    if length(sources) == 1 do
      sources
      |> hd()
      |> set_default_payment_source()
    else
      {:ok, sources}
    end
  end

  def update_payment_source(%PaymentSource{} = payment_source, params) do
    result =
      payment_source
      |> PaymentSource.changeset_for_update(params)
      |> Repo.update()

    case result do
      {:ok, ps} ->
        maybe_set_default_payment_source(ps.account_id)
        result

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def update_payment_source(id, params) do
    result =
      Repo.get(PaymentSource, id)
      |> PaymentSource.changeset_for_update(params)
      |> Repo.update()

    case result do
      {:ok, ps} ->
        maybe_set_default_payment_source(ps.account_id)
        result

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def lock_payment_source(id) do
    Repo.get(PaymentSource, id)
    |> PaymentSource.changeset(%{lock: NaiveDateTime.utc_now()})
    |> Repo.update()
  end

  def delete_payment_source(id) do
    Repo.get(PaymentSource, id)
    |> Repo.delete()
  end

  # Soft-deletes, also removes default-ness
  def delete_payment_source(id, _) do
    result = update_payment_source(id, %{active: false, is_default: false})

    case result do
      {:ok, ps} ->
        maybe_set_default_payment_source(ps.account_id)
        result

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def list_payment_sources(tenant_id) do
    from(
      p in PaymentSource,
      join: a in assoc(p, :account),
      where: a.tenant_id == ^tenant_id and p.active,
      order_by: [desc: :id]
    )
    |> Repo.all()
    # Filter out Num1 and Num2 - we should never return these
    |> Enum.map(fn p -> Map.put(p, :num1, "XXXX #{p.last_4}") end)
    |> Enum.map(fn p -> Map.put(p, :num2, "") end)
  end

  def list_payment_sources_by_account(account_id) do
    from(
      payment_source in PaymentSource,
      where: payment_source.account_id == ^account_id,
      where: payment_source.active,
      order_by: [desc: :id]
    )
    |> Repo.all()
    |> Enum.map(fn p -> Map.put(p, :num1, "XXXX #{p.last_4}") end)
    |> Enum.map(fn p -> Map.put(p, :num2, "") end)
  end

  def set_default_payment_source(%PaymentSource{} = source) do
    source
    |> PaymentSource.changeset_for_update(%{is_default: true})
    |> Repo.update()
  end

  def set_default_payment_source(%{account_id: account_id}, payment_source_id) do
    # Un-default all existing payment sources for this tenant, including
    # deactivated ones
    from(
      payment_source in PaymentSource,
      where: payment_source.account_id == ^account_id
    )
    |> Repo.update_all(set: [is_default: false])

    # Set desired as default
    update_payment_source(payment_source_id, %{is_default: true})
  end

  def cc_processor_for_tenant(nil) do
    {:error, "Payment processor not configured"}
  end

  def cc_processor_for_tenant(%AppCount.Accounts.Account{} = account) do
    account.tenant_id
    |> cc_processor_for_tenant()
  end

  # We have the account ID
  def cc_processor_for_tenant(%{account_id: account_id}) do
    Repo.get(AppCount.Accounts.Account, account_id)
    |> cc_processor_for_tenant()
  end

  # We have the tenant ID
  def cc_processor_for_tenant(tenant_id) do
    processor =
      tenant_id
      |> AppCount.Tenants.property_for()
      |> AppCount.Properties.Processors.fetch(:cc)

    case processor do
      nil -> {:error, "Payment processor not configured"}
      _ -> {:ok, processor}
    end
  end

  @doc """
  We convert params from both bank-account and CC into a normalized form.
  """
  def convert_params(%{"brand" => _} = params) do
    Enum.into(
      params,
      %{
        num1: nil,
        num2: nil,
        name: nil,
        exp: nil,
        type: nil,
        subtype: nil,
        is_default: false,
        brand: nil
      },
      fn {key, value} ->
        {@conversions[key], value}
      end
    )
  end

  def convert_params(%{"type" => "ba"} = params) do
    Map.put(params, "brand", Settings.bank_name(params["routing_number"]))
    |> convert_params
  end

  def convert_params(_), do: %{}
end
