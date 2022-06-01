defmodule AppCountWeb.OrderController do
  use AppCountWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html", %{title: "Maintenance Requests"})
  end
end
