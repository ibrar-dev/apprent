defmodule AppCount.Maintenance.Utils.Timecards do
  import Ecto.Query
  alias AppCount.Maintenance.Tech
  alias AppCount.Maintenance.Timecard
  alias AppCount.Maintenance.Assignment
  alias AppCount.Repo
  alias AppCount.Admins
  alias AppCount.Core.ClientSchema
  import AppCount.EctoExtensions

  def clock(%ClientSchema{name: client_schema, attrs: tech_id} = schema, params) do
    # FIX_DEPS
    from(c in Timecard, where: c.tech_id == ^tech_id and is_nil(c.end_ts))
    |> Repo.one(prefix: client_schema)
    |> new_entry(schema, params)
    |> Map.take([:end_ts, :tech_id])
    |> Map.put(:client_schema, client_schema)
    |> AppCountWeb.TechChannel.send_clock_data()
  end

  def create_timecard(params) do
    %Timecard{}
    |> Timecard.changeset(params)
    |> Repo.insert!()
  end

  def update_timecard(id, params) do
    Repo.get(Timecard, id)
    |> Timecard.changeset(params)
    |> Repo.update()
  end

  def new_entry(nil, %ClientSchema{name: client_schema, attrs: tech_id}, params) do
    now = Timex.to_unix(DateTime.utc_now())

    new_params =
      Map.merge(params, %{
        "start_location" => params["location"],
        "tech_id" => tech_id,
        "start_ts" => now
      })

    %Timecard{}
    |> Timecard.changeset(new_params)
    |> Repo.insert!(prefix: client_schema)
  end

  def new_entry(card, _, params) do
    now = Timex.to_unix(DateTime.utc_now())

    card
    |> Timecard.changeset(%{end_ts: now, end_location: params["location"]})
    |> Repo.update!(prefix: card.__meta__.prefix)
  end

  def get_admin_day(admin, date, end_date \\ nil) do
    property_ids = Admins.property_ids_for(admin)

    start_ts =
      Timex.beginning_of_day(date)
      |> Timex.to_unix()

    end_ts =
      Timex.end_of_day(end_date || date)
      |> Timex.to_unix()

    sub_query =
      from(
        a in Assignment,
        join: o in assoc(a, :order),
        join: p in assoc(o, :property),
        where:
          fragment("EXTRACT(EPOCH FROM ?) BETWEEN ? AND ?", a.completed_at, ^start_ts, ^end_ts),
        select: %{
          # we need a column called `id` for the jsonize macro to work
          id: a.tech_id,
          property_id: o.property_id,
          property_name: p.name,
          count: count(a.id)
        },
        group_by: [a.tech_id, o.property_id, p.id]
      )

    from(
      t in Tech,
      left_join: j in assoc(t, :jobs),
      left_join: a in subquery(sub_query),
      on: a.id == t.id,
      select: map(t, [:id, :name]),
      select_merge: %{
        completed: jsonize(a, [:count, :property_name, :property_id])
      },
      where: j.property_id in ^property_ids,
      group_by: [t.id],
      order_by: [
        asc: :name
      ]
    )
    |> Repo.all()
  end

  def get_tech_status(%ClientSchema{name: client_schema, attrs: tech_id}) do
    from(
      c in Timecard,
      limit: 1,
      where: c.tech_id == ^tech_id,
      select: %{
        end_ts: c.end_ts,
        tech_id: c.tech_id
      },
      order_by: [
        desc: c.inserted_at
      ]
    )
    |> Repo.one(prefix: client_schema)
  end

  ## Returns all the clocks for a passed in Tech, for all time
  def list_hours(tech_id) do
    from(
      c in Timecard,
      left_join: t in assoc(c, :tech),
      select: %{
        id: c.id,
        tech: t.name,
        time: c.inserted_at,
        location: c.location,
        tech_id: c.tech_id,
        status: c.status
      },
      where: c.tech_id == ^tech_id,
      order_by: [
        desc: :inserted_at
      ]
    )
    |> Repo.all()
  end
end
