defmodule AppCountWeb.ProspectController do
  use AppCountWeb, :controller
  authorize(["Admin", "Agent"])

  def index(conn, _params) do
    render(conn, "index.html", %{title: "Prospects"})
  end
end
