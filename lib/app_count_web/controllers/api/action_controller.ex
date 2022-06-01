defmodule AppCountWeb.API.ActionController do
  use AppCountWeb, :controller
  alias AppCount.Admins
  alias AppCount.Core.ClientSchema
  authorize(["Super Admin"])

  def index(conn, _params) do
    json(conn, Admins.list_actions(ClientSchema.new(conn.assigns.client_schema)))
  end

  def show(conn, %{"id" => id}) do
    json(conn, Admins.get_actions(ClientSchema.new(conn.assigns.client_schema, id)))
  end
end
