defmodule AppCountWeb.API.AdminDocumentController do
  use AppCountWeb, :controller
  alias AppCount.Properties
  alias AppCount.Core.ClientSchema

  def create(conn, %{"params" => params}) do
    params = Map.put_new(params, "creator", conn.assigns.admin.name)

    Properties.create_admin_document(ClientSchema.new(conn.assigns.client_schema, params))
    |> handle_error(conn)
  end

  def update(conn, %{"id" => id, "params" => params}) do
    Properties.update_admin_document(id, ClientSchema.new(conn.assigns.client_schema, params))

    json(conn, %{})
  end

  def delete(conn, %{"id" => id}) do
    Properties.delete_admin_document(
      ClientSchema.new(conn.assigns.client_schema, conn.assigns.admin),
      id
    )

    json(conn, %{})
  end
end
