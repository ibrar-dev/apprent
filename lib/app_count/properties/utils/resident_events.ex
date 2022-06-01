defmodule AppCount.Properties.Utils.ResidentEvents do
  import Ecto.Query
  alias AppCount.Properties.ResidentEvent
  alias AppCount.Properties.ResidentEventAttendance
  alias AppCount.Properties.Unit

  alias AppCount.Tenants.Tenant
  alias AppCount.Leases.Lease
  alias AppCount.Repo
  import AppCount.EctoExtensions

  def list_resident_events(property_id) do
    resident_event_query(property_id)
    |> Repo.all()
  end

  def list_resident_events(property_id, :upcoming) do
    current_date =
      AppCount.current_time()
      |> Timex.end_of_day()

    resident_event_query(property_id)
    |> where([e], e.date >= ^current_date)
    |> Repo.all()
  end

  def show_resident_event(id) do
    attendees =
      from(
        a in ResidentEventAttendance,
        join: t in assoc(a, :tenant),
        where: a.resident_event_id == ^id,
        select: %{
          id: a.id,
          tenant_id: a.tenant_id,
          resident_event_id: a.resident_event_id,
          name: fragment("? || ' ' || ?", t.first_name, t.last_name)
        },
        group_by: [t.id, a.id]
      )

    from(
      e in ResidentEvent,
      join: p in assoc(e, :property),
      left_join: a in subquery(attendees),
      left_join: i in assoc(e, :image_url),
      on: a.resident_event_id == e.id,
      where: e.id == ^id,
      select: map(e, [:id, :name, :location, :info, :date, :start_time, :end_time, :admin]),
      select_merge: %{
        property: map(p, [:id, :name, :logo, :icon, :address]),
        attendees: jsonize(a, [:id, :name, :tenant_id]),
        image: i.url
      },
      group_by: [e.id, p.id, i.url]
    )
    |> Repo.one()
  end

  def create_resident_event(params) do
    %ResidentEvent{}
    |> ResidentEvent.changeset(params)
    |> Repo.insert()
    |> case do
      {:ok, event} -> notify_residents(event, params)
      {:error, _} -> nil
    end
  end

  def update_resident_event(id, params) do
    Repo.get(ResidentEvent, id)
    |> ResidentEvent.changeset(params)
    |> Repo.update()
  end

  def notify_residents(event, params) do
    case params["notify"] do
      "true" -> send_emails(event)
      _ -> {:ok, event}
    end
  end

  def send_emails(event) do
    AppCount.Core.Tasker.start(fn -> send_emails_task(event) end)
    {:ok, event}
  end

  # UNTESTED
  def send_emails_task(event) do
    event = Repo.get(ResidentEvent, event.id)

    now =
      AppCount.current_time()
      |> Timex.to_date()

    lease_query =
      from(
        l in Lease,
        left_join: o in assoc(l, :occupancies),
        left_join: c in assoc(l, :charges),
        left_join: a in assoc(c, :account),
        on: c.lease_id == l.id,
        join: u in assoc(l, :unit),
        join: p in assoc(u, :property),
        select: %{
          id: l.id,
          tenant_id: o.tenant_id,
          unit_id: l.unit_id
        },
        where: p.id == ^event.property_id,
        where:
          is_nil(l.actual_move_out) and l.start_date <= ^now and l.end_date >= ^now and
            l.actual_move_in <= ^now,
        group_by: [l.id, p.id, o.tenant_id]
      )

    from(
      t in Tenant,
      join: l in subquery(lease_query),
      on: l.tenant_id == t.id,
      join: u in Unit,
      on: u.id == l.unit_id,
      join: p in assoc(u, :property),
      left_join: lo in assoc(p, :logo_url),
      select: %{
        id: t.id,
        name: fragment("? || ' ' || ?", t.first_name, t.last_name),
        email: t.email,
        property: merge(p, %{logo: lo.url})
      },
      distinct: u.id,
      where: not is_nil(t.email)
    )
    |> Repo.all()
    |> Enum.each(fn t -> AppCountCom.Tenants.new_resident_event(t, event) end)
  end

  def delete_resident_event(id) do
    Repo.get(ResidentEvent, id)
    |> Repo.delete()
  end

  defp resident_event_query(property_id) do
    from(
      e in ResidentEvent,
      join: p in assoc(e, :property),
      left_join: i in assoc(e, :image_url),
      where: e.property_id == ^property_id,
      select:
        map(e, [:id, :name, :location, :info, :date, :start_time, :end_time, :admin, :inserted_at]),
      select_merge: %{
        property: map(p, [:id, :name, :logo, :icon, :address]),
        image: i.url
      },
      order_by: [
        asc: :date
      ]
    )
  end
end
