defmodule AppCount.Yardi.ImportResidents do
  alias AppCount.Properties.Property
  alias AppCount.Properties.Processors
  alias AppCount.Tenants.TenantRepo
  alias AppCount.Tenants.TenancyRepo
  alias AppCount.Leasing.LeaseRepo
  require Logger
  alias AppCount.Core.ClientSchema

  def perform(property, gateway \\ Yardi.Gateway)

  def perform(
        %ClientSchema{name: client_schema, attrs: %Property{external_id: external_id, id: id}},
        gateway
      )
      when is_binary(external_id) do
    credentials =
      Processors.processor_credentials(ClientSchema.new(client_schema, id), "management")

    resident_import =
      gateway.import_residents(external_id, credentials)
      |> handle_resident_import_response

    gateway.get_tenants(external_id, credentials)
    |> handle_response(id, ClientSchema.new(client_schema, resident_import))
  end

  def perform(%ClientSchema{attrs: %Property{} = p}, _),
    do: raise("No external ID found for property #{p.name}")

  def perform(%ClientSchema{name: client_schema, attrs: property_id}, gateway),
    do:
      perform(
        %ClientSchema{
          name: client_schema,
          attrs: AppCount.Repo.get(Property, property_id, prefix: client_schema)
        },
        gateway
      )

  def handle_resident_import_response({:ok, residents}) do
    Enum.into(residents, %{}, fn resident -> {resident.external_id, resident} end)
  end

  def handle_resident_import_response({:error, _}), do: %{}

  def handle_response({:ok, tenants}, property_id, %ClientSchema{
        name: client_schema,
        attrs: resident_import
      }) do
    tenants
    |> Enum.map(&merge_resident_import(&1, resident_import))
    |> Enum.filter(&real_tenant?/1)
    |> Enum.each(
      &process_tenant_data(&1, %ClientSchema{
        name: client_schema,
        attrs: property_id
      })
    )

    # tenants
    # |> Enum.map(&merge_resident_import(&1, resident_import))
    # |> Enum.each(&process_tenant_data(&1, property_id))
  end

  def handle_response({:error, message}, _, _),
    do: Logger.warn("Yardi Import residents error: #{message}")

  def process_tenant_data(attrs, %ClientSchema{
        name: client_schema,
        attrs: property_id
      }) do
    attrs =
      attrs
      |> sort_attrs(property_id)

    ClientSchema.new(client_schema, attrs)
    |> process_attrs
  end

  def sort_attrs(attrs, property_id) do
    unit = AppCount.Yardi.ImportResidents.Unit.get_or_insert_unit(attrs.unit_code, property_id)

    %{
      tenant_attrs: tenant_attrs(attrs),
      tenancy_attrs: tenancy_attrs(attrs, unit),
      lease_attrs: lease_attrs(attrs, unit)
    }
  end

  def tenant_attrs(attrs) do
    Map.take(attrs, [:first_name, :last_name, :email, :phone, :payment_accepted])
    |> Map.put(:external_id, attrs.p_code)
  end

  def tenancy_attrs(attrs, unit) do
    %{
      notice_date: attrs.notice_date,
      expected_move_in: attrs.move_in_date,
      expected_move_out: attrs.move_out_date,
      actual_move_in: Map.get(attrs, :actual_move_in_date),
      actual_move_out: Map.get(attrs, :actual_move_out_date),
      external_id: attrs.t_code,
      unit_id: unit.id
    }
  end

  def lease_attrs(attrs, unit) do
    %{
      start_date: attrs.lease_from_date,
      date: attrs.lease_from_date,
      end_date: attrs.lease_to_date,
      unit_id: unit.id
    }
  end

  def process_attrs(%ClientSchema{
        name: client_schema,
        attrs: attrs
      }) do
    %ClientSchema{
      name: client_schema,
      attrs: attrs
    }
    |> process_tenant()
    |> process_tenancy_and_lease(%ClientSchema{
      name: client_schema,
      attrs: attrs
    })
    |> maybe_create_account()
    |> maybe_lock_account(attrs.tenant_attrs)
  end

  def process_tenant(%ClientSchema{
        name: _client_schema,
        attrs: %{tenant_attrs: tenant_attrs}
      }) do
    params =
      tenant_attrs
      |> Map.take([:first_name, :last_name, :email, :phone, :external_id])
      |> strip_missing_email()
      |> strip_missing_phone()
      |> merge_required()

    case TenantRepo.get_by(external_id: params.external_id) do
      nil ->
        {:ok, tenant} = TenantRepo.insert(params)
        {:new_tenant, tenant}

      existing_tenant ->
        {:ok, updated} = TenantRepo.update(existing_tenant, params)
        {:existing_tenant, updated}
    end
  end

  def process_tenancy_and_lease(
        {status, tenant},
        %ClientSchema{
          name: client_schema,
          attrs: %{
            tenancy_attrs: tenancy_attrs,
            lease_attrs: lease_attrs
          }
        }
      ) do
    case TenancyRepo.get_by([external_id: tenancy_attrs.external_id], prefix: client_schema) do
      nil ->
        attrs =
          tenancy_attrs
          |> Map.merge(lease_attrs)
          |> Map.merge(%{tenant_id: tenant.id, charges: []})

        ClientSchema.new(client_schema, attrs)
        |> AppCount.Leasing.Utils.CreateNewTenancy.create_new_tenancy()

      tenancy ->
        {:ok, updated} = TenancyRepo.update(tenancy, tenancy_attrs, prefix: client_schema)
        handle_possible_lease_changes(lease_attrs, updated)
    end

    {status, tenant}
  end

  def handle_possible_lease_changes(lease_attrs, tenancy) do
    case LeaseRepo.leases_by_customer_id(
           ClientSchema.new(tenancy.__meta__.prefix, tenancy.customer_ledger_id)
         ) do
      [lease] ->
        LeaseRepo.update(lease, lease_attrs, prefix: tenancy.__meta__.prefix)

      [] ->
        lease_attrs
        |> Map.put(:customer_ledger_id, tenancy.customer_ledger_id)
        |> LeaseRepo.insert(prefix: tenancy.__meta__.prefix)

      [first_lease | rest] ->
        Enum.each(rest, &LeaseRepo.delete(&1.id, prefix: tenancy.__meta__.prefix))
        LeaseRepo.update(first_lease, lease_attrs, prefix: tenancy.__meta__.prefix)
    end
  end

  # If Yardi does not provide an email, we want to avoid overwriting that email
  # address in AppRent
  def strip_missing_email(%{email: email} = params) when is_nil(email) or email == "" do
    Map.drop(params, [:email])
  end

  # Yardi provides an email address - use it
  def strip_missing_email(params) do
    params
  end

  # If Yardi doesn't have a phone number on record, we want to avoid overwriting
  # any phone numbers that might exist in the AppRent system
  def strip_missing_phone(%{phone: phone} = params) when is_nil(phone) or phone == "" do
    Map.drop(params, [:phone])
  end

  # Yardi has a phone number - use it
  def strip_missing_phone(params) do
    params
  end

  defp merge_required(params) do
    [:first_name, :last_name]
    |> Enum.reduce(params, &merge_if_nil/2)
  end

  defp merge_if_nil(field, params) do
    if params[field] do
      params
    else
      Map.put(params, field, "_")
    end
  end

  defp merge_resident_import(%{t_code: t_code} = tenant, resident_import) do
    (resident_import[t_code] || %{})
    |> Map.take([:payment_accepted, :actual_move_out_date, :actual_move_in_date, :current_rent])
    |> Map.merge(tenant)
  end

  defp maybe_lock_account(tenant, %{payment_accepted: pa}) when pa in ["1", "2"] do
    AppCount.Accounts.lock_account(tenant.id, "Payments must be made in person in the office.")
    tenant
  end

  defp maybe_lock_account(tenant, _), do: tenant

  defp maybe_create_account({:new_tenant, tenant}) do
    AppCount.Accounts.create_tenant_account(tenant.id)
    tenant
  end

  defp maybe_create_account({_, tenant}), do: tenant

  defp real_tenant?(%{status: "Applicant"}), do: false

  defp real_tenant?(%{unit_code: unit_number}) do
    !String.match?(unit_number, ~r/WAIT/i)
  end
end
