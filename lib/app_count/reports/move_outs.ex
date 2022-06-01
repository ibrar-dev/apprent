defmodule AppCount.Reports.MoveOuts do
  alias AppCount.Repo
  alias AppCount.Leases.Lease
  import Ecto.Query

  def report(admin, property_id, start, end_date) do
    from(
      l in Lease,
      join: u in assoc(l, :unit),
      join: r in assoc(l, :move_out_reason),
      where: u.property_id in ^admin.property_ids,
      where: u.property_id == ^property_id,
      where: l.actual_move_out >= ^start,
      where: l.actual_move_out <= ^end_date,
      select: %{id: l.move_out_reason_id, name: r.name, count: count(l.move_out_reason_id)},
      group_by: [l.move_out_reason_id, r.name]
    )
    |> Repo.all()
  end
end
