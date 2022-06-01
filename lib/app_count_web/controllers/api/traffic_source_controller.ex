defmodule AppCountWeb.API.TrafficSourceController do
  use AppCountWeb, :controller
  alias AppCount.Prospects
  authorize(["Admin", "Agent"])

  def index(conn, _params) do
    json(conn, Prospects.list_traffic_sources())
  end

  def create(conn, %{"traffic_source" => params}) do
    Prospects.create_traffic_source(params)
    json(conn, %{})
  end

  def update(conn, %{"id" => id, "traffic_source" => params}) do
    Prospects.update_traffic_source(id, params)
    json(conn, %{})
  end

  def delete(conn, %{"id" => id}) do
    Prospects.delete_traffic_source(id)
    json(conn, %{})
  end
end
