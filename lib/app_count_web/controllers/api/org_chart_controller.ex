defmodule AppCountWeb.API.OrgChartController do
  use AppCountWeb, :controller
  alias AppCount.Admins
  alias AppCount.Core.ClientSchema

  authorize(["Admin", "Super Admin"])

  def create(conn, %{"root" => params}) do
    Admins.create_root(ClientSchema.new(conn.assigns.client_schema, params))
    json(conn, %{})
  end

  def create(conn, %{"data" => data}) do
    Admins.update_org(
      ClientSchema.new(
        conn.assigns.client_schema,
        data
      )
    )

    json(conn, %{})
  end

  def index(conn, %{"everyone" => _}) do
    json(conn, Admins.get_everyone(ClientSchema.new(conn.assigns.client_schema)))
  end

  def index(conn, %{"descendants" => _}) do
    json(
      conn,
      Admins.descendants(ClientSchema.new(conn.assigns.client_schema, conn.assigns.admin))
    )
  end

  def index(conn, _params) do
    json(conn, Admins.list_org(ClientSchema.new(conn.assigns.client_schema, conn.assigns.admin)))
  end
end
