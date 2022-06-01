defmodule AppCountWeb.OpeningController do
  use AppCountWeb, :controller
  authorize(["Admin"])

  def index(conn, _params) do
    render(conn, "index.html", %{title: "Tour Hours"})
  end
end
