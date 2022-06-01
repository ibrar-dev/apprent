defmodule AppCountWeb.MaintenanceReportController do
  use AppCountWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html", %{title: "Maintenance Reports"})
  end
end
