defmodule AppCount.Properties.Utils.Events do
  alias AppCount.Repo
  alias AppCount.Properties.ResidentEvent
  alias AppCount.Leases.Lease
  alias AppCount.Prospects.Showing
  import Ecto.Query

  def list_events(%{property_ids: property_ids}) do
    list_events(property_ids)
  end

  def list_events(property_ids) do
    now =
      AppCount.current_time()
      |> Timex.beginning_of_day()

    %{
      move_out: move_outs(property_ids, now),
      move_in: move_ins(property_ids, now),
      showing: showings(property_ids, now),
      resident_event: resident_events(property_ids, now)
    }
  end

  defp showings(property_ids, now) do
    from(
      s in Showing,
      join: pr in assoc(s, :property),
      join: p in assoc(s, :prospect),
      left_join: u in assoc(s, :unit),
      where: pr.id in ^property_ids and s.date >= ^now,
      select: %{
        id: s.id,
        unit: map(u, [:id, :number]),
        prospect: map(p, [:id, :name]),
        property: pr.name,
        date: s.date,
        time: [s.start_time, s.end_time],
        cancellation: s.cancellation
      }
    )
    |> Repo.all()
  end

  defp move_ins(property_ids, now) do
    from(
      l in Lease,
      join: u in assoc(l, :unit),
      join: t in assoc(l, :tenants),
      join: p in assoc(u, :property),
      where:
        p.id in ^property_ids and not is_nil(l.expected_move_in) and l.expected_move_in >= ^now,
      select: %{
        id: l.id,
        unit: map(u, [:id, :number]),
        tenant: map(t, [:id, :first_name, :last_name]),
        property: p.name,
        date: l.expected_move_in
      }
    )
    |> Repo.all()
  end

  defp move_outs(property_ids, now) do
    from(
      l in Lease,
      join: u in assoc(l, :unit),
      join: t in assoc(l, :tenants),
      join: p in assoc(u, :property),
      where: p.id in ^property_ids and not is_nil(l.move_out_date) and l.move_out_date >= ^now,
      select: %{
        id: l.id,
        unit: map(u, [:id, :number]),
        tenant: map(t, [:id, :first_name, :last_name]),
        property: p.name,
        date: l.move_out_date
      }
    )
    |> Repo.all()
  end

  defp resident_events(property_ids, now) do
    from(
      e in ResidentEvent,
      join: p in assoc(e, :property),
      select: %{
        id: e.id,
        property: p.name,
        date: e.date,
        name: e.name,
        start_time: e.start_time,
        admin: e.admin
      },
      where: e.date >= ^now and e.property_id in ^property_ids
    )
    |> Repo.all()
  end
end
