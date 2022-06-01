defmodule AppCountWeb.DashboardController do
  use AppCountWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html", %{title: "Home"})
  end
end
