defmodule AppCount.Leasing.BlueMoon.Renewals do
  alias AppCount.Leasing.Lease
  alias AppCount.Tenants.Tenancy
  alias AppCount.Units
  alias AppCount.Repo
  alias AppCount.Leasing.BlueMoon.GetLease
  import Ecto.Query
  import AppCount.EctoExtensions
  use AppCount.Decimal
  alias AppCount.Core.ClientSchema

  def renewal_params(
        %ClientSchema{
          name: client_schema,
          attrs: lease_id
        },
        params,
        bluemoon_gateway \\ BlueMoon
      ) do
    # TODO add occupants once we bring them over into leasing/tenancies
    %{lease: lease, unit: unit, tenants: tenants} =
      from(
        lease in Lease,
        where: lease.id == ^lease_id,
        join: tenancy in Tenancy,
        on: tenancy.customer_ledger_id == lease.customer_ledger_id,
        #        left_join: o in assoc(l, :occupants),
        join: unit in assoc(tenancy, :unit),
        join: tenant in assoc(tenancy, :tenant),
        select: %{
          lease: lease,
          unit: unit,
          tenants: jsonize(tenant, [:id, :first_name, :last_name, :email, :phone])
        },
        group_by: [lease.id, unit.id]
      )
      |> Repo.one(prefix: client_schema)

    signators =
      Enum.map(
        tenants,
        &%{name: "#{&1["first_name"]} #{&1["last_name"]}", email: &1["email"], phone: &1["phone"]}
      )

    dates = %{
      #      start_date: params["start_date"] || Timex.shift(lease.end_date, days: 1),
      start_date: params["start_date"] || lease.end_date,
      end_date:
        params["end_date"] ||
          Timex.shift(lease.end_date, years: 1)
          |> Timex.shift(days: -1)
    }

    charges_total =
      Enum.reduce(Units.default_charges(params["unit_id"] || unit.id), 0, &(&1.price + &2))

    {unit, rent} =
      if params["unit_id"] do
        {
          Repo.get(
            Unit,
            params["unit_id"],
            prefix: client_schema
          ),
          charges_total + Units.market_rent(params["unit_id"])
        }
      else
        {unit,
         AppCount.Leasing.Utils.RenewalRent.rent_for(
           ClientSchema.new(client_schema, %{lease | unit: unit}),
           dates.start_date,
           dates.end_date
         ) + charges_total}
      end

    case GetLease.get_lease(
           ClientSchema.new(client_schema, unit.property_id),
           lease.pending_external_id,
           bluemoon_gateway
         ) do
      %BlueMoon.Data.Lease{} = result -> result
      _ -> default_lease_params(tenants, [])
    end
    |> Map.from_struct()
    |> Map.merge(dates)
    |> Map.merge(%{
      unit: unit.number,
      rent: rent,
      signators: signators,
      property_id: unit.property_id
    })
  end

  defp default_lease_params(tenants, occupants) do
    %{
      residents: Enum.map(tenants, &"#{&1["first_name"]} #{&1["last_name"]}"),
      occupants: Enum.map(occupants, &"#{&1["first_name"]} #{&1["last_name"]}")
    }
    |> BlueMoon.Data.Lease.cast_params()
  end
end
