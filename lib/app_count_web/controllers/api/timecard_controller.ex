defmodule AppCountWeb.API.TimecardController do
  use AppCountWeb, :controller
  alias AppCount.Maintenance
  alias AppCount.Core.ClientSchema

  def index(conn, %{"start_date" => start_date, "end_date" => end_date} = _) do
    {:ok, timex_start_date} = Timex.parse(start_date, "{ISO:Extended:Z}")
    {:ok, timex_end_date} = Timex.parse(end_date, "{ISO:Extended:Z}")

    json(conn, %{
      techs: Maintenance.get_admin_day(conn.assigns.admin, timex_start_date, timex_end_date),
      make_readies:
        Maintenance.get_ready_by_dates(
          ClientSchema.new(conn.assigns.admin),
          timex_start_date,
          timex_end_date
        )
    })
  end

  def create(conn, %{"timecard" => params}) do
    Maintenance.create_timecard(params)
    json(conn, %{})
  end

  def update(conn, %{"id" => id, "timecard" => params}) do
    Maintenance.update_timecard(id, params)
    json(conn, %{})
  end
end
