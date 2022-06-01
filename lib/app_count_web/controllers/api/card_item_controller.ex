defmodule AppCountWeb.API.CardItemController do
  use AppCountWeb, :controller
  alias AppCount.Maintenance
  alias AppCount.Core.ClientSchema

  authorize(["Tech", "Admin"], update: ["Tech", "Admin", "Agent"])

  def create(conn, %{"card_item" => params}) do
    Maintenance.create_card_item(
      ClientSchema.new(conn.assigns.client_schema, params),
      conn.assigns.admin
    )
    |> handle_error(conn)
  end

  def update(conn, %{"id" => id, "card_item" => params, "complete" => _}) do
    new_params = Map.put(params, "admin_id", conn.assigns.admin.id)

    Maintenance.complete_card_item(
      id,
      ClientSchema.new(conn.assigns.client_schema, new_params),
      conn.assigns.admin
    )
    |> handle_error(conn)
  end

  def update(conn, %{"id" => id, "card_item" => params, "revert" => _}) do
    new_params = Map.put(params, "admin_id", conn.assigns.admin.id)

    Maintenance.revert_card_item(id, ClientSchema.new(conn.assigns.client_schema, new_params))
    |> handle_error(conn)
  end

  def update(conn, %{"id" => id, "card_item" => params, "confirm" => _}) do
    # TO DO: This should really confirm card items via admin ID

    Maintenance.confirm_card_item(
      id,
      ClientSchema.new(conn.assigns.client_schema, params),
      conn.assigns.admin.name
    )
    |> handle_error(conn)
  end

  def update(conn, %{"id" => id, "card_item" => params}) do
    new_params = Map.put(params, "admin", conn.assigns.admin)

    Maintenance.update_card_item(id, ClientSchema.new(conn.assigns.client_schema, new_params))
    |> handle_error(conn)
  end

  def delete(conn, %{"id" => id}) do
    Maintenance.delete_card_item(
      conn.assigns.admin,
      ClientSchema.new(conn.assigns.client_schema, id)
    )
    |> handle_error(conn)
  end
end
