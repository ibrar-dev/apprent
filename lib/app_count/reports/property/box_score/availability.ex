defmodule AppCount.Reports.Property.BoxScore.Availability do
  use AppCount.Decimal
  import Ecto.Query
  import AppCount.EctoExtensions
  alias AppCount.Repo
  alias AppCount.Reports.Queries
  alias AppCount.Reports.BoxScore.Calculations
  alias AppCount.Properties.FloorPlan
  alias AppCount.Properties.Unit
  alias AppCount.Leasing.Lease

  # HOW IS AVG RENT CALCULATED...?

  ## Per Floor Plan:
  ### Availability
  #### FPNAME | Sq Ft | Avg Rent | Units | Occupied | Vacant Rented | Vacant Unrented | Notice Rented | Notice Unrented | Available | Model | Down | % Occupied | % Occupied w/ non rev | % Leased | % Trend
  #### Total:  | AVG SqFt | Avg Rent | Sum --------------------------------------------------------------------------------------------------------| AVG Percentage --------------------------------------|

  def floor_plan(fp_id, end_date) do
    property = get_property(fp_id)

    from(
      fp in FloorPlan,
      where: fp.id == ^fp_id,
      left_join: u in subquery(unit_query(property.id, end_date)),
      on: u.floor_plan_id == fp.id,
      select: %{
        id: fp.id,
        name: fp.name,
        unit_count: count(u.id),
        avg_sq_ft: avg(u.sq_ft),
        avg_rent: avg(u.market_rent),
        units: jsonize(u, [:id, :number, :status, :lease_end, :tenants])
      },
      group_by: [fp.id]
    )
    |> Repo.one()
    |> group_status
    |> get_calculations
    |> combine_available
  end

  defp unit_query(property_id, end_date) do
    from(
      u in Unit,
      join: s in subquery(Queries.unit_status(property_id, end_date)),
      on: s.id == u.id,
      join: mr in subquery(Queries.market_rent(property_id, end_date)),
      on: mr.unit_id == u.id,
      left_join: tenancy in assoc(u, :tenancies),
      left_join: t in assoc(tenancy, :tenant),
      left_join: lease in Lease,
      on:
        lease.customer_ledger_id == tenancy.customer_ledger_id and lease.start_date <= ^end_date,
      select: %{
        id: u.id,
        floor_plan_id: u.floor_plan_id,
        sq_ft: u.area,
        status: s.status,
        number: u.number,
        market_rent: mr.market_rent,
        lease_end: max(lease.end_date),
        tenants: jsonize(t, [:id, {:name, fragment("? || ' ' || ?", t.first_name, t.last_name)}])
      },
      distinct: u.id,
      group_by: [u.id, s.status, mr.market_rent]
    )
  end

  defp get_property(fp_id) do
    from(
      f in FloorPlan,
      where: f.id == ^fp_id,
      join: p in assoc(f, :property),
      select: p
    )
    |> Repo.one()
  end

  def get_status(property_id, end_date, status) do
    unit_query(property_id, end_date)
    |> where([_, s], s.status in ^status)
  end

  def group_status(%{units: units} = fp) do
    stats = %{
      occupied: ["Occupied"],
      vacant_rented: ["Vacant Rented Ready", "Vacant Rented Not Ready"],
      vacant_unrented: ["Vacant Unrented Not Ready", "Vacant Unrented Ready"],
      notice_rented: ["Notice Rented"],
      notice_unrented: ["Notice Unrented"],
      model: ["MODEL"],
      down: ["DOWN"]
    }

    grouped =
      Enum.reduce(
        units,
        %{
          occupied: %{count: 0, units: []},
          vacant_rented: %{count: 0, units: []},
          vacant_unrented: %{count: 0, units: []},
          notice_rented: %{count: 0, units: []},
          notice_unrented: %{count: 0, units: []},
          model: %{count: 0, units: []},
          down: %{count: 0, units: []},
          misc: %{count: 0, units: []}
        },
        fn u, acc ->
          first_match(stats, u["status"])
          |> case do
            {key, _} ->
              new_val = %{count: acc[key][:count] + 1, units: acc[key][:units] ++ [u]}

              Map.update!(acc, key, fn _ ->
                new_val
              end)

            _ ->
              new_val = %{count: acc[:misc][:count] + 1, units: acc[:misc][:units] ++ [u]}

              Map.update!(acc, :misc, fn _ ->
                new_val
              end)
          end
        end
      )

    Map.replace!(fp, :units, grouped)
  end

  def get_calculations(%{units: units, unit_count: unit_count} = fp) do
    calculations = Calculations.get_calculations(unit_count, units)
    Map.merge(fp, %{calculations: calculations})
  end

  def combine_available(%{units: %{notice_unrented: nur, vacant_unrented: vur}} = fp) do
    new_units =
      Map.merge(fp.units, %{
        available: %{count: nur.count + vur.count, units: nur.units ++ vur.units}
      })

    Map.replace!(fp, :units, new_units)
  end

  def first_match(collection, search) do
    Enum.find(collection, fn {_, v} ->
      Enum.member?(v, search)
    end)
  end

  def all_matches(collection, search) do
    Enum.filter(collection, fn {_, v} ->
      Enum.member?(v, search)
    end)
  end
end
