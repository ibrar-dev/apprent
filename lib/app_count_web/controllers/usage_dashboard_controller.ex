defmodule AppCountWeb.UsageDashboardController do
  use AppCountWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html", %{title: "30 Days Usage"})
  end
end
