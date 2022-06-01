defmodule AppCountWeb.PropertyReportController do
  use AppCountWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html", %{title: "Property Report"})
  end
end
