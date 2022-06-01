defmodule AppCountWeb.ApplicationController do
  use AppCountWeb, :controller
  authorize(["Admin", "Agent"])

  def index(conn, _params) do
    render(conn, "index.html", %{title: "Applications"})
  end
end
