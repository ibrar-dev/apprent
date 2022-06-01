defmodule AppCountWeb.API.OpeningController do
  use AppCountWeb, :controller
  alias AppCount.Prospects
  alias AppCount.Core.ClientSchema
  authorize(["Regional", "Admin"], index: ["Admin", "Agent"])

  def index(conn, _params) do
    json(
      conn,
      Prospects.list_openings(ClientSchema.new(conn.assigns.client_schema, conn.assigns.admin))
    )
  end

  def create(conn, %{"opening" => params}) do
    Prospects.create_opening(ClientSchema.new(conn.assigns.client_schema, params))
    json(conn, %{})
  end

  def update(conn, %{"id" => id, "opening" => params}) do
    Prospects.update_opening(ClientSchema.new(conn.assigns.client_schema, id), params)
    json(conn, %{})
  end

  def delete(conn, %{"id" => id}) do
    Prospects.delete_opening(ClientSchema.new(conn.assigns.client_schema, id))
    json(conn, %{})
  end
end
