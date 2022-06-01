defmodule AppCountWeb.API.FeatureController do
  use AppCountWeb, :controller
  alias AppCount.Properties
  alias AppCount.Core.ClientSchema
  authorize(["Admin"])

  action_fallback(AppCountWeb.FallbackController)

  def index(conn, _params) do
    json(conn, Properties.list_features(ClientSchema.new(conn.assigns.admin)))
  end

  def create(conn, %{"feature" => params}) do
    Properties.create_feature(ClientSchema.new(conn.assigns.client_schema, params))
    |> handle_error(conn)
  end

  def update(conn, %{"id" => id, "feature" => params}) do
    Properties.update_feature(
      id,
      ClientSchema.new(conn.assigns.client_schema, params)
    )
    |> handle_error(conn)
  end

  def delete(conn, %{"id" => id}) do
    Properties.delete_feature(ClientSchema.new(conn.assigns.client_schema, id))
    |> handle_error(conn)
  end
end
