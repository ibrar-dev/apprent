defmodule AppCountWeb.API.IntegrationController do
  use AppCountWeb, :controller
  alias AppCount.Properties
  alias AppCount.Core.ClientSchema

  authorize(["Super Admin"])

  def index(conn, _) do
    json(conn, Properties.list_processors(ClientSchema.new(conn.assigns.client_schema)))
    # json(conn, Properties.list_processors(ClientSchema.new(conn.assigns.client_schem)))
  end

  def show(conn, %{"id" => id, "bluemoon_id" => _}) do
    {:ok, data} =
      Properties.get_bluemoon_property_ids(ClientSchema.new(conn.assigns.client_schema, id))

    json(conn, data)
  end

  def create(conn, %{"create_account" => account_params, "processor" => params}) do
    Properties.create_payscape_account_and_processor(
      ClientSchema.new(conn.assigns.client_schema, account_params),
      params
    )
    |> handle_error(conn)
  end

  def create(conn, %{"processor" => params}) do
    Properties.create_processor(ClientSchema.new(conn.assigns.client_schema, params))
    |> handle_error(conn)
  end

  def update(conn, %{"id" => id, "processor" => params}) do
    Properties.update_processor(ClientSchema.new(conn.assigns.client_schema, id), params)
    |> handle_error(conn)
  end

  def delete(conn, %{"id" => id}) do
    Properties.delete_processor(ClientSchema.new(conn.assigns.client_schema, id))
    |> handle_error(conn)
  end
end
