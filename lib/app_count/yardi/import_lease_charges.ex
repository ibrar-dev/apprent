defmodule AppCount.Yardi.ImportLeaseCharges do
  alias AppCount.Properties.Processors
  alias AppCount.Repo
  alias AppCount.Tenants.TenantRepo
  alias AppCount.Ledgers.ChargeCodeRepo
  alias AppCount.Core.ClientSchema

  def import(tenant_id, gateway \\ Yardi.Gateway) do
    tenant_yardi_id = TenantRepo.get(tenant_id).external_id

    property =
      TenantRepo.current_lease_for(tenant_id)
      |> Repo.preload(unit: :property)
      |> Map.get(:unit)
      |> Map.get(:property)

    credentials =
      Processors.processor_credentials(
        ClientSchema.new("dasmen", property.id),
        "management"
      )

    if !!property.external_id and !!tenant_yardi_id and !!credentials do
      gateway.get_resident_lease_charges(property.external_id, tenant_yardi_id, credentials)
      |> case do
        {:ok, result} ->
          converted =
            result
            |> Enum.map(&to_lease_charges/1)
            |> Enum.filter(& &1)

          {:ok, converted}

        _ ->
          nil
      end
    end
  end

  defp to_lease_charges(yardi_params) do
    charge_code = ChargeCodeRepo.get_by(code: yardi_params.charge_code)

    if charge_code do
      %{
        amount: yardi_params.amount,
        charge_code_id: charge_code.id,
        from_date: yardi_params.start_date,
        to_date: yardi_params.end_date
      }
    end
  end
end
