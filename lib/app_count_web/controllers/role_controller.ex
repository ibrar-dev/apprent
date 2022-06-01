defmodule AppCountWeb.RoleController do
  use AppCountWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html", %{title: "Roles"})
  end
end
