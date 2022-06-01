defmodule AppCount.Yardi.ImportLedger do
  require Logger
  alias AppCount.Repo
  alias AppCount.Properties.Property
  alias AppCount.Properties.Processors
  alias AppCount.Tenants.Tenancy
  alias AppCount.Tenants.TenancyRepo
  use AppCount.Decimal
  alias AppCount.Core.ClientSchema

  def perform(property_id, tenancy_id, gateway \\ Yardi.Gateway)

  def perform(
        %Property{id: pid, external_id: property_external_id},
        %Tenancy{id: tid, external_id: tenant_external_id} = tenancy,
        gateway
      )
      when is_binary(property_external_id) and is_binary(tenant_external_id) do
    Logger.info("Ledger import for tenant #{tenant_external_id}. ID: #{tid}")

    credentials = Processors.processor_credentials(ClientSchema.new("dasmen", pid), "management")

    if credentials do
      gateway.get_resident_data(property_external_id, tenant_external_id, credentials)
      |> perform_import(tenancy)
    else
      {:error, "Missing property integration"}
    end
  end

  def perform(%Property{} = p, %Tenancy{}, _),
    do: raise("No external ID found for property #{p.name}")

  def perform(property_id, tenancy_id, gateway) do
    perform(Repo.get(Property, property_id), Repo.get(Tenancy, tenancy_id), gateway)
  end

  def perform_import(data, tenancy) do
    balance = Enum.reduce(data, 0, &balance_accumulator/2)
    TenancyRepo.update(tenancy, %{external_balance: balance})
  end

  def balance_accumulator(%Yardi.Response.GetResidentData.Payment{amount: amount}, acc) do
    acc - amount
  end

  def balance_accumulator(%Yardi.Response.GetResidentData.Charge{amount: amount}, acc) do
    acc + amount
  end
end
