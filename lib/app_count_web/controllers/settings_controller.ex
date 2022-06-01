defmodule AppCountWeb.SettingsController do
  use AppCountWeb, :controller

  authorize(["Super Admin"])

  def index(conn, _params) do
    render(conn, "index.html", %{title: "Settings"})
  end
end
