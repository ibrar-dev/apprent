defmodule AppCount.Tenants.Utils.ExternalIdSync do
  import Ecto.Query
  alias AppCount.Repo
  alias AppCount.Tenants.TenancyRepo
  alias AppCount.Core.ClientSchema

  def sync_external_id(tenancy_id, gateway \\ Yardi.Gateway) do
    data =
      TenancyRepo.tenancies_with_property_query()
      |> join(:inner, [t], tenant in assoc(t, :tenant))
      |> where([t], t.id == ^tenancy_id)
      |> select(
        [tenancy, unit, property, tenant],
        %{
          unit_id: unit.id,
          unit_number: unit.number,
          property_id: property.id,
          property_external_id: property.external_id,
          tenancy_id: tenancy.id,
          tenant_external_id: tenancy.external_id,
          first_name: tenant.first_name,
          last_name: tenant.last_name
        }
      )
      |> Repo.one()

    if data do
      do_sync_external_id(data, gateway)
    else
      {:error, "Tenant not found"}
    end
  end

  defp do_sync_external_id(data, gateway) do
    credentials =
      AppCount.Properties.Processors.processor_credentials(
        ClientSchema.new("dasmen", data.property_id),
        "management"
      )

    gateway.get_tenants_by_unit(data.property_external_id, data.unit_number, credentials)
    |> Enum.find(&(&1.status == "Current"))
    |> check_name(data)
  end

  def check_name(nil, _), do: {:error, "no current tenant in external system"}

  def check_name(%{t_code: new_code}, %{tenant: %{external_id: current_code}})
      when current_code == new_code,
      do: {:ok, %{external_id: current_code}}

  def check_name(%{first_name: first, last_name: last, t_code: t_code}, tenant) do
    if String.jaro_distance(tenant.first_name, first) > 0.75 and
         String.jaro_distance(tenant.last_name, last) > 0.75 do
      TenancyRepo.get(tenant.tenancy_id)
      |> TenancyRepo.update(%{external_id: t_code})
    else
      {:error, "Current tenant listed in Yardi as: #{first} #{last}(#{t_code})"}
    end
  end
end
