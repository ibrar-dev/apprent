defmodule AppCountWeb.API.UserStatController do
  use AppCountWeb, :controller
  alias AppCount.Core.ClientSchema

  def index(conn, _params) do
    json(conn, AppCount.Accounts.admin_stats(ClientSchema.new(conn.assigns.admin)))
  end

  def create(conn, %{"property_ids" => property_ids}) do
    json(
      conn,
      AppCount.Accounts.admin_stats(
        ClientSchema.new(conn.assigns.client_schema, conn.assigns.admin),
        property_ids
      )
    )
  end
end
