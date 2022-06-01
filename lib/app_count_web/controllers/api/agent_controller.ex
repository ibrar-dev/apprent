defmodule AppCountWeb.API.AgentController do
  use AppCountWeb, :controller
  alias AppCount.Admins
  alias AppCount.Core.ClientSchema

  def index(conn, _params) do
    json(
      conn,
      Admins.list_agents(
        ClientSchema.new(
          conn.assigns.client_schema,
          conn.assigns.admin
        )
      )
    )
  end
end
