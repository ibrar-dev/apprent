defmodule AppCount.Leases.ExternalLedgerBoundary do
  alias AppCount.Repo
  alias AppCount.Tenants.TenancyRepo
  alias AppCount.Properties.Processors
  alias AppCount.Admins
  use AppCount.Decimal
  alias AppCount.Core.ClientSchema

  def ledger_details(external_id, module \\ __MODULE__) do
    external_id
    |> module.entries()
    |> module.save_balance(external_id)
    |> module.yardi_to_map()
  end

  def entries(tenant_external_id, adapter \\ Yardi.Gateway) do
    tenancy =
      TenancyRepo.get_by(external_id: tenant_external_id)
      |> Repo.preload(unit: :property)

    credentials =
      Processors.processor_credentials(
        ClientSchema.new("dasmen", tenancy.unit.property_id),
        "management"
      )

    adapter.get_resident_data(tenancy.unit.property.external_id, tenant_external_id, credentials)
  end

  def save_balance(entries, external_id, repo \\ TenancyRepo)

  def save_balance(entries, external_id, repo) when is_list(entries) do
    balance = balance_as_decimal(entries)

    repo.get_by(external_id: external_id)
    |> repo.update(%{external_balance: balance})

    entries
  end

  def save_balance(_, _, _), do: []

  def balance_as_decimal(entries) do
    entries
    |> Enum.reduce(Decimal.new(0), fn entry, acc ->
      Decimal.add(acc, amount_as_decimal(entry))
    end)
  end

  # Currently only checks to make sure that the passed in Admin is in the correct property.
  # Future features may want to also limit by Admin roles or further granularity.
  def can_access(admin, external_id) do
    Admins.property_ids_for(ClientSchema.new("dasmen", admin))
    |> Enum.member?(property_id_from_external_id(external_id))
  end

  defp amount_as_decimal(%Yardi.Response.GetResidentData.Payment{} = entry) do
    to_decimal(entry.amount)
    |> Decimal.mult(-1)
  end

  defp amount_as_decimal(%Yardi.Response.GetResidentData.Charge{} = entry),
    do: to_decimal(entry.amount)

  def yardi_to_map(entries) when is_list(entries) do
    entries
    |> Enum.map(&yardi_to_map(&1))
  end

  def yardi_to_map(%Yardi.Response.GetResidentData.Payment{} = entry) do
    Yardi.Response.GetResidentData.Payment.to_map(entry)
  end

  def yardi_to_map(%Yardi.Response.GetResidentData.Charge{} = entry) do
    Yardi.Response.GetResidentData.Charge.to_map(entry)
  end

  defp property_id_from_external_id(external_id) do
    tenancy =
      TenancyRepo.get_by(external_id: external_id)
      |> Repo.preload(:unit)

    tenancy.unit.property_id
  end
end
