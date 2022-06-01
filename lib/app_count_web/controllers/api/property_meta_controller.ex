defmodule AppCountWeb.API.PropertyMetaController do
  use AppCountWeb, :controller
  alias AppCount.Properties
  alias AppCount.Core.ClientSchema

  def index(conn, _params) do
    data =
      Properties.list_properties(
        ClientSchema.new(conn.assigns.client_schema, conn.assigns.admin),
        :min
      )

    json(conn, data)
  end
end
