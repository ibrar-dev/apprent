defmodule AppCountWeb.API.OccupantController do
  use AppCountWeb, :controller
  alias AppCount.Properties
  alias AppCount.Core.ClientSchema

  def create(conn, %{"occupant" => params}) do
    Properties.create_occupant(ClientSchema.new(conn.assigns.client_schema, params))
    |> handle_error(conn)
  end

  def update(conn, %{"id" => id, "occupant" => params}) do
    Properties.update_occupant(id, ClientSchema.new(conn.assigns.client_schema, params))
    |> handle_error(conn)
  end

  def delete(conn, %{"id" => id}) do
    Properties.delete_occupant(
      ClientSchema.new(conn.assigns.client_schema, conn.assigns.admin),
      id
    )
    |> handle_error(conn)
  end
end
