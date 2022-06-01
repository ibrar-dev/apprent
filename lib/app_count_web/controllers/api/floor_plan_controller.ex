defmodule AppCountWeb.API.FloorPlanController do
  use AppCountWeb, :controller
  alias AppCount.Properties
  alias AppCount.Core.ClientSchema
  authorize(["Admin"])

  action_fallback(AppCountWeb.FallbackController)

  def index(conn, _params) do
    json(conn, Properties.list_floor_plans(ClientSchema.new(conn.assigns.admin)))
  end

  def create(conn, %{"floor_plan" => params}) do
    Properties.create_floor_plan(ClientSchema.new(conn.assigns.client_schema, params))
    json(conn, %{})
  end

  def update(conn, %{"id" => id, "floor_plan" => params}) do
    Properties.update_floor_plan(id, ClientSchema.new(conn.assigns.client_schema, params))
    json(conn, %{})
  end

  def delete(conn, %{"id" => id}) do
    Properties.delete_floor_plan(ClientSchema.new(conn.assigns.client_schema, id))
    json(conn, %{})
  end
end
