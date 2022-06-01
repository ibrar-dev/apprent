defmodule AppCountWeb.SystemSettingsController do
  use AppCountWeb, :controller

  authorize(["Super Admin"])

  def index(conn, _params) do
    render(conn, "index.html", %{title: "System Settings"})
  end
end
