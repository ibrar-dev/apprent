defmodule AppCountWeb.API.V1.CategoryController do
  use AppCountWeb, :controller

  authorize(["Tech", "Accountant", "Admin"])

  def index(conn, _params) do
    json(conn, maintenance(conn).v1_list_categories(conn.assigns.client_schema))
  end
end
