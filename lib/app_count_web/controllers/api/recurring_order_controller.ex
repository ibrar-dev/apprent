defmodule AppCountWeb.API.RecurringOrderController do
  use AppCountWeb, :controller
  alias AppCount.Core.ClientSchema
  authorize(["Admin", "Tech"])

  action_fallback(AppCountWeb.FallbackController)

  def index(conn, _params) do
    s_json(conn, maintenance(conn).list_recurring_orders(conn.assigns.admin))
  end

  def create(conn, %{"recurring_order" => params}) do
    params =
      params
      |> Map.put("admin_id", conn.assigns.admin.id)

    maintenance(conn).create_recurring_order(ClientSchema.new(conn.assigns.client_schema, params))

    json(conn, %{})
  end

  def update(conn, %{"id" => id, "recurring_order" => params}) do
    maintenance(conn).update_recurring_order(id, params)
    json(conn, %{})
  end

  def delete(conn, %{"id" => id}) do
    maintenance(conn).delete_recurring_order(id)
    json(conn, %{})
  end
end
