defmodule AppCountWeb.API.OpenHistoriesController do
  use AppCountWeb, :controller
  alias AppCount.Maintenance

  def index(conn, %{"date" => date}) do
    s_json(conn, Maintenance.list_open_histories(conn.assigns.admin, date))
  end

  def index(conn, %{"startDate" => start_date, "endDate" => end_date}) do
    s_json(
      conn,
      Maintenance.list_open_histories(
        conn.assigns.admin,
        Timex.parse!(start_date, "{YYYY}-{0M}-{D}"),
        Timex.parse!(end_date, "{YYYY}-{0M}-{D}")
      )
    )
  end
end
