defmodule AppCountWeb.MigrationController do
  use AppCountWeb, :controller
  authorize([])

  def index(conn, _params) do
    render(conn, "index.html", %{title: "Migrations"})
  end
end
