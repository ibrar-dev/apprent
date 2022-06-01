defmodule AppCount.Tasks.Workers.ShowingAlert do
  import Ecto.Query
  alias AppCount.Repo
  alias AppCount.Admins
  alias AppCount.Prospects.Showing
  use AppCount.Tasks.Worker, "Send showing alerts"
  alias AppCount.Core.ClientSchema

  @impl AppCount.Tasks.Worker
  def perform(schema \\ "dasmen") do
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
      |> Repo.all(prefix: schema)

    cond do
      length(tours) >= 1 -> Enum.each(tours, fn x -> create_tour_alert(x) end)
      true -> nil
    end
  end

  defp create_tour_alert(%{property_id: property_id, name: name}) do
    (Admins.admins_for(ClientSchema.new("dasmen", property_id), ["Agent"]) ++
       Admins.admins_for(ClientSchema.new("dasmen", property_id), ["Admin"]))
    |> Enum.uniq()
    |> Enum.each(fn x ->
      Admins.create_alert(%{
        sender: "Tours",
        note: "You have a tour in 15 minutes with #{name}",
        admin_id: x.id,
        flag: 4
      })
    end)
  end
end
