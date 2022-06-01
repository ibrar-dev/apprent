defmodule AppCountWeb.API.PropertyListController do
  use AppCountWeb, :public_controller
  alias AppCount.Core.ClientSchema

  action_fallback(AppCountWeb.FallbackController)

  def index(conn, %{"code" => code}) do
    %{__meta__: meta} = AppCount.Public.PropertyRepo.client_property_from_code(code)
    client_schema = AppCount.Core.ClientSchema.new(meta.prefix, %{code: code})
    json(conn, AppCount.Properties.public_property_data(client_schema))
  end

  def index(conn, _) do
    json(conn, AppCount.Properties.list_public_properties(ClientSchema.new("dasmen")))
  end
end
