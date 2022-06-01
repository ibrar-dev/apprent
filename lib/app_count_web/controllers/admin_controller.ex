defmodule AppCountWeb.AdminController do
  use AppCountWeb, :controller
  authorize([])

  def index(conn, _params) do
    render(conn, "index.html", %{title: "Admins"})
  end
end
