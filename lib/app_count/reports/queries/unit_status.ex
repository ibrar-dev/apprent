defmodule AppCount.Reports.Queries.UnitStatus do
  import Ecto.Query
  alias AppCount.Properties.Unit
  alias AppCount.Reports.Queries
  alias AppCount.Maintenance.Card

  def get_status(property_id, date) when not is_list(property_id),
    do: get_status([property_id], date)

  def get_status(property_ids, date) do
    from(
      u in Unit,
      left_join: tenancy in assoc(u, :tenancies),
      on: tenancy.unit_id == u.id and tenancy.start_date <= ^date,
      left_join: future_tenancy in assoc(u, :tenancies),
      on: future_tenancy.unit_id == u.id and future_tenancy.start_date > ^date,
      where: u.property_id in ^property_ids,
      left_join: r in subquery(ready_query(date)),
      on: u.id == r.unit_id,
      select: %{
        id: u.id,
        number: u.number,
        is_occupied:
          fragment(
            "bool_or(? IS NULL) AND bool_or(? IS NOT NULL)",
            tenancy.actual_move_out,
            tenancy.id
          ),
        is_notice:
          fragment(
            "bool_or(? IS NOT NULL AND ? IS NULL)",
            tenancy.notice_date,
            tenancy.actual_move_out
          ),
        is_rented: fragment("bool_or(? IS NOT NULL)", future_tenancy.id),
        is_ready: fragment("bool_or(? IS NOT NULL)", r.id),
        floor_plan_id: u.floor_plan_id,
        status: u.status
      },
      group_by: u.id
    )
  end

  def full_unit_status(property_ids, date) when not is_list(property_ids),
    do: full_unit_status([property_ids], date)

  def full_unit_status(property_ids, date) do
    get_status(property_ids, date)
    |> subquery
    |> select(
      [unit],
      %{
        id: unit.id,
        number: unit.number,
        floor_plan_id: unit.floor_plan_id,
        status:
          fragment(
            "CASE
                  WHEN ? IS NOT NULL THEN ?
                  WHEN ? THEN 'Vacant Unrented Not Ready'
                  WHEN ? THEN 'Vacant Unrented Ready'
                  WHEN ? THEN 'Vacant Rented Not Ready'
                  WHEN ? THEN 'Vacant Rented Ready'
                  WHEN ? THEN 'Notice Unrented'
                  WHEN ? THEN 'Notice Rented'
                  WHEN ? THEN 'Occupied'
               END",
            unit.status,
            unit.status,
            not unit.is_occupied and not unit.is_rented and not unit.is_ready,
            not unit.is_occupied and not unit.is_rented and unit.is_ready,
            not unit.is_occupied and unit.is_rented and not unit.is_ready,
            not unit.is_occupied and unit.is_rented and unit.is_ready,
            unit.is_notice and not unit.is_rented,
            unit.is_notice and unit.is_rented,
            unit.is_occupied
          )
      }
    )
  end

  def fetch_box_score(property_id, date \\ AppCount.current_date()) do
    get_status(property_id, date)
    |> join(
      :left,
      [u],
      mr in subquery(Queries.MarketRent.market_rent_query(property_id, date)),
      on: mr.unit_id == u.id
    )
    |> join(:left, [u], f in assoc(u, :floor_plan))
    |> select_merge(
      [u, vunr, vur, vrnr, vrr, nnr, nr, occ, mr, f],
      %{
        floor_plan: f.name,
        market_rent: mr.market_rent,
        vunr: vunr,
        vur: vur,
        vrnr: vrnr,
        vrr: vrr,
        nnr: nnr,
        nr: nr,
        occ: occ
      }
    )
    |> AppCount.Repo.all()
  end

  def ready_query(date) do
    # we need this subquery bc we want to only get cards that have been created
    # after the most recent move out and completed prior to the date inputted
    unit_move_out_query =
      from(
        t in AppCount.Tenants.Tenancy,
        where: not is_nil(t.actual_move_out) and t.actual_move_out < ^date,
        order_by: [
          desc: t.actual_move_out
        ],
        limit: 1
      )

    from(
      c in Card,
      left_join: mo in subquery(unit_move_out_query),
      on: c.unit_id == mo.unit_id,
      where: c.inserted_at >= mo.actual_move_out,
      where: not is_nil(c.completion) and fragment("(completion->>'date')::date") <= ^date,
      select: %{
        id: c.id,
        unit_id: c.unit_id
      }
    )
  end
end
