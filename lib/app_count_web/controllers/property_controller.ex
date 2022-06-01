defmodule AppCountWeb.PropertyController do
  use AppCountWeb, :controller
  authorize(["Admin"])

  def index(conn, _params) do
    render(conn, "index.html", %{title: "Properties"})
  end
end
