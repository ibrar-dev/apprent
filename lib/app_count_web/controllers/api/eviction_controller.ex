defmodule AppCountWeb.API.EvictionController do
  use AppCountWeb, :controller
  alias AppCount.Properties

  authorize(["Admin"])

  def create(conn, %{"eviction" => params}) do
    Properties.create_eviction(params)
    json(conn, %{})
  end

  def update(conn, %{"id" => id, "eviction" => params}) do
    Properties.update_eviction(id, params)
    json(conn, %{})
  end

  def delete(conn, %{"id" => id}) do
    Properties.delete_eviction(id)
    json(conn, %{})
  end
end
