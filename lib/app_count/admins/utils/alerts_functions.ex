defmodule AppCount.Admins.Utils.AlertsFunctions do
  import Ecto.Query
  alias AppCount.Repo
  alias AppCount.Admins
  alias AppCount.Prospects.Showing
  alias AppCount.Core.ClientSchema

  def fifteen_minute_showings_alerts(%AppCount.Core.ClientSchema{name: client_schema}) do
    day_start = AppCount.current_time() |> Timex.beginning_of_day()
    minutes = Timex.diff(AppCount.current_time(), day_start, :minutes)

    tours =
      from(
        s in Showing,
        join: p in assoc(s, :prospect),
        where: s.date == ^Timex.to_date(AppCount.current_time()) and is_nil(s.cancellation),
        where: s.start_time > ^minutes and s.start_time <= ^(minutes + 15),
        select: %{
          id: s.id,
          name: p.name,
          property_id: s.property_id
        }
      )
      |> Repo.all(prefix: client_schema)

    cond do
      length(tours) >= 1 -> Enum.each(tours, fn x -> create_tour_alert(x) end)
      true -> nil
    end
  end

  defp create_tour_alert(%AppCount.Core.ClientSchema{
         name: client_schema,
         attrs: %{property_id: property_id, name: name}
       }) do
    (Admins.admins_for(ClientSchema.new(client_schema, property_id), ["Agent"]) ++
       Admins.admins_for(ClientSchema.new(client_schema, property_id), ["Admin"]))
    |> Enum.uniq()
    |> Enum.each(fn x ->
      Admins.create_alert(
        ClientSchema.new(client_schema, %{
          sender: "Tours",
          note: "You have a tour in 15 minutes with #{name}",
          admin_id: x.id,
          flag: 4
        })
      )
    end)
  end
end
