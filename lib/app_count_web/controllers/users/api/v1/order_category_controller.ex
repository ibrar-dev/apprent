defmodule AppCountWeb.Users.API.V1.OrderCategoryController do
  use AppCountWeb.Users, :controller
  alias AppCount.Maintenance

  def index(conn, _) do
    json(conn, Maintenance.list_categories(conn.assigns.user.client_schema))
  end
end
