defmodule AppCountWeb.TenantController do
  use AppCountWeb, :controller
  authorize(["Admin", "Agent"])

  def index(conn, _params) do
    render(conn, "index.html", id: "null", title: "Residents")
  end

  def show(conn, %{"id" => id}) do
    render(conn, "index.html", %{id: id, title: "Residents"})
  end
end
