defmodule AppCount.Reports.ExpiringLeases do
  import Ecto.Query
  alias AppCount.Repo
  alias AppCount.Properties.FloorPlan
  alias AppCount.Leasing.Lease
  alias AppCount.Tenants.Tenancy

  # This report gets all the floorplans for a property and a starting date
  # It then gets all the leases, grouped by floorplan that are expiring within that month and the following 11 months.
  def run_report(property_id, date \\ nil) do
    starting_month = convert_month_to_dates(date)

    from(
      f in FloorPlan,
      join: u in assoc(f, :units),
      where: f.property_id == ^property_id,
      select: %{
        id: f.id,
        name: f.name,
        units: count(u.id),
        property_id: f.property_id
      },
      group_by: [f.id],
      order_by: [
        asc: :name
      ]
    )
    |> Repo.all()
    |> Enum.map(&get_expiring_by_fp(&1, starting_month))
  end

  defp get_expiring_by_fp(data, %{start_d: start_d} = starting_month) do
    nums =
      Enum.reduce(
        1..11,
        [%{month: start_d, units: get_month(data, starting_month)}],
        fn num, acc ->
          dates = convert_month_to_dates(Timex.shift(start_d, months: num))
          acc ++ [%{month: dates.start_d, units: get_month(data, dates)}]
        end
      )

    Map.merge(data, %{months: nums, mtm: get_mtm(data, start_d)})
  end

  defp get_mtm(%{id: id, property_id: property_id}, start_d) do
    from(
      lease in Lease,
      join: unit in assoc(lease, :unit),
      join: tenancy in Tenancy,
      on: tenancy.customer_ledger_id == lease.customer_ledger_id,
      where: is_nil(tenancy.actual_move_out) or tenancy.actual_move_out >= ^start_d,
      where: not is_nil(tenancy.actual_move_in),
      where: lease.end_date < ^start_d,
      where: unit.floor_plan_id == ^id,
      where: unit.property_id == ^property_id,
      select: %{
        unit: unit.number
      },
      order_by: [asc: lease.end_date]
    )
    |> Repo.all()
  end

  # floorplan_id and month to find expiring leases, property_id: for the LeaseBlock query
  defp get_month(%{id: id, property_id: property_id}, %{start_d: start_d, end_d: end_d}) do
    from(
      lease in Lease,
      join: unit in assoc(lease, :unit),
      join: tenancy in Tenancy,
      on: tenancy.customer_ledger_id == lease.customer_ledger_id,
      where: is_nil(tenancy.actual_move_out),
      where: not is_nil(tenancy.actual_move_in),
      where: lease.end_date >= ^start_d,
      where: lease.end_date <= ^end_d,
      where: unit.floor_plan_id == ^id,
      where: unit.property_id == ^property_id,
      select: %{
        unit: unit.number
      },
      order_by: [asc: lease.end_date]
    )
    |> Repo.all()
  end

  defp convert_month_to_dates(month) do
    cond do
      is_nil(month) ->
        %{
          start_d: Timex.beginning_of_month(AppCount.current_date()),
          end_d: Timex.end_of_month(AppCount.current_date())
        }

      Timex.is_valid?(month) ->
        %{start_d: Timex.beginning_of_month(month), end_d: Timex.end_of_month(month)}

      true ->
        Date.from_iso8601!(month)
        |> convert_month_to_dates
    end
  end
end
