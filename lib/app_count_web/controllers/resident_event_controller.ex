defmodule AppCountWeb.ResidentEventController do
  use AppCountWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html", %{title: "Resident Events"})
  end
end
