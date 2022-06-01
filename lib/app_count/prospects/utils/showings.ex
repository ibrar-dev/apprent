defmodule AppCount.Prospects.Utils.Showings do
  import Ecto.Query
  import AppCount.Utils, only: [indifferent: 2]
  alias AppCount.Repo
  alias AppCount.Admins
  alias AppCount.Prospects.Showing
  alias AppCount.Prospects.Opening
  alias AppCount.Core.ClientSchema

  def list_showings(admin) do
    from(
      s in Showing,
      join: p in assoc(s, :prospect),
      join: pro in assoc(s, :property),
      left_join: u in assoc(s, :unit),
      where: s.property_id in ^Admins.property_ids_for(ClientSchema.new("dasmen", admin)),
      select: %{
        id: s.id,
        date: s.date,
        prospect: p.name,
        prospect_type: p.contact_type,
        property: pro.name,
        unit: u.number,
        property_id: s.property_id,
        start_time: s.start_time,
        end_time: s.end_time
      }
    )
    |> Repo.all()
  end

  def create_showing(params) do
    if validate(params) do
      %Showing{}
      |> Showing.changeset(params)
      |> Repo.insert()
      |> send_confirmation_email
      |> notify_admins
    else
      {:error, :unavailable}
    end
  end

  def get_showing(id) do
    Repo.get(Showing, id)
  end

  def update_showing(id, params) do
    if validate(params, id) do
      Repo.get(Showing, id)
      |> Showing.changeset(params)
      |> Repo.update()
    else
      {:error, :unavailable}
    end
  end

  def delete_showing(id) do
    Repo.get(Showing, id)
    |> Repo.delete()
  end

  def notify_admins({:ok, %{property_id: property_id, prospect_id: prospect_id} = s}) do
    AppCount.Core.Tasker.start(fn ->
      property = AppCount.Properties.get_property(ClientSchema.new("dasmen", property_id))
      prospect = Repo.get(AppCount.Prospects.Prospect, prospect_id)

      AppCount.Admins.admins_for(ClientSchema.new("dasmen", property_id))
      |> Enum.each(fn admin ->
        AppCountCom.Showings.showing_scheduled(admin, prospect, property, s)
        AppCount.Core.Sleeper.sleep(1000)
      end)
    end)

    {:ok, s}
  end

  def notify_admins(e), do: e

  def send_confirmation_email({:ok, %{property_id: property_id, prospect_id: prospect_id} = s}) do
    AppCount.Core.Tasker.start(fn ->
      prospect = Repo.get(AppCount.Prospects.Prospect, prospect_id)
      property = AppCount.Properties.get_property(ClientSchema.new("dasmen", property_id))
      AppCountCom.Showings.showing_scheduled(prospect, property, s)
    end)

    {:ok, s}
  end

  def send_confirmation_email(e), do: e

  def send_reminder_email() do
    from(
      s in Showing,
      join: property in assoc(s, :property),
      left_join: logo in assoc(property, :logo_url),
      join: p in assoc(s, :prospect),
      select: %{
        id: s.id,
        date: s.date,
        start_time: s.start_time,
        property: merge(property, %{logo: logo.url}),
        name: p.name,
        email: p.email
      },
      where: fragment("current_date - ? = -1", s.date) and is_nil(s.cancellation)
    )
    |> Repo.all()
    |> Enum.each(&AppCountCom.Showings.showing_reminder_email/1)
  end

  defp validate(params, id \\ 0) do
    overlapping_showings_for(params, id) < available_slots_for(params)
  end

  defp overlapping_showings_for(params, id) do
    to_extract = [:date, :property_id, :start_time, :end_time]
    [date, property_id, start_time, end_time] = indifferent(params, to_extract)

    cond do
      is_nil(date) and is_nil(start_time) and is_nil(end_time) ->
        0

      true ->
        from(
          s in Showing,
          where:
            s.date == ^date and s.property_id == ^property_id and s.start_time < ^end_time and
              s.end_time > ^start_time,
          where: s.id != ^id,
          select: count(s.id)
        )
        |> Repo.one()
    end
  end

  defp available_slots_for(params) do
    to_extract = [:date, :property_id, :start_time, :end_time]
    [date, property_id, start_time, end_time] = indifferent(params, to_extract)

    cond do
      is_nil(date) and is_nil(start_time) and is_nil(end_time) ->
        1

      true ->
        wday =
          Date.from_iso8601!(date)
          |> Date.day_of_week()

        from(
          o in Opening,
          where:
            o.property_id == ^property_id and o.wday == ^wday and o.start_time <= ^start_time and
              o.end_time >= ^end_time,
          select: max(o.showing_slots)
        )
        |> Repo.one()
    end
  end
end
