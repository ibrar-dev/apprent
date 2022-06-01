defmodule AppCount.Reports.Property.BoxScore.ResidentActivity do
  import Ecto.Query
  alias AppCount.Repo
  alias AppCount.Properties.FloorPlan
  alias AppCount.Leases.Lease

  ### Resident Activity between the given start and end date
  #### FPName | Units √ | Move In √ | Move Out √ | Notice √ | ?Rented? | Transfer | MTM √ | Renewal | Evict √
  #### Totals | SUM ----------------------------------------------------------------------------|
  def floor_plan(fp_id, start_date, end_date) do
    # unused ?
    _property = get_property(fp_id)

    from(
      fp in FloorPlan,
      left_join: u in assoc(fp, :units),
      where: fp.id == ^fp_id,
      select: map(fp, [:id, :name]),
      select_merge: %{
        unit_count: count(u.id)
      },
      group_by: [fp.id]
    )
    |> Repo.one()
    |> add_in_status(fp_id, start_date, end_date, :actual_move_in)
    |> add_in_status(fp_id, start_date, end_date, :actual_move_out)
    |> add_in_status(fp_id, start_date, end_date, :notice_date, [
      {:actual_move_out, nil},
      {:renewal_id, nil}
    ])
    |> add_in_status(fp_id, start_date, end_date, :end_date, [
      {:actual_move_out, nil},
      {:renewal_id, nil}
    ])
    |> add_in_others(fp_id, start_date, end_date)
  end

  def add_in_others(attrs, fp_id, start_date, end_date) do
    evictions = get_evictions(fp_id, start_date, end_date)
    renewals = get_renewals(fp_id, start_date, end_date)

    others = %{
      evictions: %{count: length(evictions), units: evictions},
      renewals: %{count: length(renewals), unit: renewals}
    }

    Map.merge(attrs, others)
  end

  def add_in_status(attrs, fp_id, start_date, end_date, field, opts \\ []) do
    leases = lease_status(fp_id, start_date, end_date, field, opts)

    attrs
    |> Map.put(field, %{count: length(leases), units: leases})
  end

  # needs: Unit resident(id and name), date, status, Rent, Deposit, Move In, Lease Expiration, lease_id for query
  # Status will be interesting
  def lease_status(fp_id, start_date, end_date, field, opts \\ []) do
    from(
      l in Lease,
      join: u in assoc(l, :unit),
      where: fragment("? between ? and ?", field(l, ^field), ^start_date, ^end_date),
      where: u.floor_plan_id == ^fp_id,
      select: %{
        id: l.id,
        number: u.number,
        fp_id: u.floor_plan_id
      }
      #      group_by: [l.id, u.id]
    )
    |> where_clauses(opts)
    |> Repo.all()
  end

  def where_clauses(query, []), do: query

  def where_clauses(query, [{column, value} | opts]) when is_nil(value) do
    query
    |> where([l], is_nil(field(l, ^column)))
    |> where_clauses(opts)
  end

  def where_clauses(query, [{column, value} | opts]) do
    query
    |> where([l], field(l, ^column) == ^value)
    |> where_clauses(opts)
  end

  def get_evictions(fp_id, start_d, end_d) do
    from(
      l in Lease,
      join: u in assoc(l, :unit),
      join: e in assoc(l, :eviction),
      where: fragment("? between ? and ?", e.file_date, ^start_d, ^end_d),
      where: u.floor_plan_id == ^fp_id,
      select: %{
        id: l.id,
        number: u.number,
        fp_id: u.floor_plan_id
      }
    )
    |> Repo.all()
  end

  def get_renewals(fp_id, start_d, end_d) do
    from(
      l in Lease,
      join: u in assoc(l, :unit),
      join: r in assoc(l, :renewal),
      where: u.floor_plan_id == ^fp_id,
      where: fragment("?::TIMESTAMP::DATE between ? and ?", r.lease_date, ^start_d, ^end_d),
      select: %{
        id: r.id,
        number: u.number,
        fp_id: u.floor_plan_id
      }
    )
    |> Repo.all()
  end

  def tenants_subquery() do
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
end
