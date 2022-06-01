defmodule AppCountWeb.API.BatchController do
  use AppCountWeb, :controller
  alias AppCount.Ledgers.Utils.Batches
  alias AppCount.Core.ClientSchema

  def index(conn, params) do
    json(
      conn,
      Batches.list_batches(
        ClientSchema.new(conn.assigns.client_schema, conn.assigns.admin),
        params
      )
    )
  end

  def create(conn, %{"check" => params}) do
    params = Map.put(params, "source", "admin")

    Batches.check_valid(ClientSchema.new(conn.assigns.client_schema, params))
    |> handle_error(conn)
  end

  def create(conn, %{"batch" => params}) do
    params =
      params
      |> Map.put("admin", conn.assigns.admin)

    ClientSchema.new(conn.assigns.client_schema, params)
    |> Batches.create_batch()
    |> handle_error(conn)
  end

  def update(conn, %{"id" => id, "batch" => params}) do
    new_params = Map.merge(params, %{"closed_by" => conn.assigns.admin.name})
    Batches.update_batch(id, ClientSchema.new(conn.assigns.client_schema, new_params))
    json(conn, %{})
  end

  def delete(conn, %{"id" => id}) do
    Batches.delete_batch(conn.assigns.admin, ClientSchema.new(conn.assigns.client_schema, id))

    json(conn, %{})
  end
end
