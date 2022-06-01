##   You may ask what is the point of this. Well AppCount.Properties.Utils.Reports was getting really crowded
##   and these functions are more for calculations such as trend and any other specific calculations that will
##   need to be called in multiple places. That's what this file is for. Please group each calculation together.
defmodule AppCount.Properties.Utils.Calculations do
  use AppCount.Decimal
  import Ecto.Query
  alias AppCount.Repo
  alias AppCount.Properties.Unit
  alias AppCount.Reports.Queries

  ########## TREND CALCULATION ##########
  def calculate_trend(property_ids, days \\ nil) do
    %{trend: trend} = calculate_trend_detailed(property_ids, days)
    trend
  end

  def calculate_trend_multiple(property_ids) do
    %{
      thirty: calculate_trend(property_ids, 30),
      sixty: calculate_trend(property_ids, 60),
      one_twenty: calculate_trend(property_ids, 120),
      indefinite: calculate_trend(property_ids, 9999)
    }
  end

  def calculate_trend_detailed(property_ids, days \\ nil) do
    end_date =
      case days do
        nil ->
          AppCount.current_time()

        _ ->
          Timex.shift(AppCount.current_time(), days: days)
          |> Timex.end_of_day()
      end

    # Units that are on notice
    notice_units =
      cond do
        is_nil(days) -> notice_units(property_ids)
        true -> notice_units(property_ids, end_date)
      end

    # Model units
    models = find_model_units(property_ids)
    # Units with a status of occupied, function needs two arguments even though its never used
    occupied_units =
      occupied_units(property_ids, end_date)
      |> length

    # Total - Model units
    total_units = total_units(property_ids) - models
    trend = (occupied_units - notice_units) / total_units * 100

    %{
      trend: trend,
      occupied_units: occupied_units,
      notice_units: notice_units,
      model_units: models,
      total_units: total_units
    }
  end

  # last_lease_id: fragment("?[array_length(?, 1)]", l.lease_ids, l.lease_ids),
  def notice_units_query(property_ids) do
    from(
      t in AppCount.Tenants.Tenancy,
      join: u in assoc(t, :unit),
      where: not is_nil(t.notice_date) and is_nil(t.actual_move_out),
      where: u.property_id in ^property_ids,
      distinct: t.unit_id,
      order_by: [desc: t.notice_date],
      select: %{
        id: u.id,
        property_id: u.property_id,
        move_out_date: t.expected_move_out
      }
    )
  end

  def notice_units(property_ids) do
    notice_units_query(property_ids)
    |> Repo.all()
    |> length
  end

  #
  def notice_units(property_ids, end_date) do
    notice_units_query(property_ids)
    |> where([t], t.expected_move_out <= ^end_date)
    |> Repo.all()
    |> length
  end

  def total_units(property_ids) do
    from(
      u in Unit,
      where: u.property_id in ^property_ids,
      select: count(u.id)
    )
    |> Repo.one()
  end

  def find_model_units(property_ids) do
    from(
      u in Unit,
      select: u.id,
      where: u.property_id in ^property_ids and u.status == "MODEL"
    )
    |> Repo.all()
    |> length
  end

  def available_units(property_ids) do
    AppCount.Properties.Utils.Units.list_rentable(property_ids)
    |> length
  end

  def occupied_units(property_ids, _date \\ nil) do
    date = AppCount.current_date()

    from(
      u in Unit,
      join: p in assoc(u, :property),
      join: t in assoc(u, :tenancies),
      join: l in AppCount.Leasing.Lease,
      on: l.customer_ledger_id == t.customer_ledger_id,
      where: t.start_date <= ^date,
      where: p.id in ^property_ids,
      where: is_nil(t.actual_move_out),
      select: %{
        id: u.id,
        property_id: u.property_id,
        property: p.name,
        unit_id: u.id,
        unit: u.number,
        start_date: min(t.start_date),
        end_date: max(l.end_date),
        floor_plan_id: u.floor_plan_id
      },
      group_by: [u.id, p.id]
    )
    |> Repo.all()
  end

  # NEED occ/ occ non-rev/ leased and trend
  # Pass unit_count, %{down: down, model: model, notice_rented: nr, notice_unrented: nur, occupied: occ, vacant_rented: vr}
  # into AppCount.Reports.BoxScore.Calculations where each one has that number in count
  #  def property_calculations(property_id, date) when not is_list(property_id), do: property_calculations([property_id], date)
  def property_calculations(property_id, date) do
    units = Repo.all(Queries.full_unit_status(property_id, date))

    grouped = %{
      model: %{count: length(Enum.filter(units, &(&1.status == "MODEL")))},
      down: %{count: length(Enum.filter(units, &(&1.status == "DOWN")))},
      notice_rented: %{count: length(Enum.filter(units, &(&1.status == "Notice Rented")))},
      notice_unrented: %{count: length(Enum.filter(units, &(&1.status == "Notice Unrented")))},
      occupied: %{count: length(Enum.filter(units, &(&1.status == "Occupied")))},
      vacant_rented: %{
        count:
          length(
            Enum.filter(units, &(&1.status in ["Vacant Rented Ready", "Vacant Rented Not Ready"]))
          )
      }
    }

    AppCount.Reports.BoxScore.Calculations.get_calculations(length(units), grouped)
  end
end
