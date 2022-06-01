defmodule AppCountWeb.API.PropertyController do
  use AppCountWeb, :controller
  alias AppCount.Properties
  alias AppCount.Core.ClientSchema

  authorize(["Admin"], create: [], delete: [], index: ["Agent", "Tech", "Admin"])

  action_fallback(AppCountWeb.FallbackController)

  def index(conn, %{"min" => _}) do
    json(
      conn,
      Properties.list_properties(
        ClientSchema.new(conn.assigns.admin),
        :min
      )
    )
  end

  def index(conn, _params) do
    json(
      conn,
      Properties.list_properties(ClientSchema.new(conn.assigns.admin))
    )
  end

  def create(conn, %{"property" => params}) do
    with {:ok, _} <-
           Properties.create_property(ClientSchema.new(conn.assigns.admin.client_schema, params)),
         do: json(conn, %{})
  end

  def show(conn, %{"id" => id}) do
    json(
      conn,
      Properties.get_property(
        conn.assigns.admin,
        ClientSchema.new(conn.assigns.client_schema, id)
      )
    )
  end

  def update(conn, %{"id" => id, "property" => params}) do
    {:ok, _} =
      Properties.update_property(
        id,
        ClientSchema.new(
          conn.assigns.client_schema,
          params
        )
      )

    json(conn, %{})
  end

  def delete(conn, %{"id" => id}) do
    Properties.delete_property(
      ClientSchema.new(
        conn.assigns.client_schema,
        id
      )
    )

    json(conn, %{})
  end
end
