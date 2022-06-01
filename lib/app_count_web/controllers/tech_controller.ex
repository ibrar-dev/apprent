defmodule AppCountWeb.TechController do
  use AppCountWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html", %{title: "Maintenance Technicians"})
  end
end
