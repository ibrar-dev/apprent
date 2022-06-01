defmodule AppCountWeb.API.V1.TechController do
  use AppCountWeb, :controller
  alias AppCount.Core.ClientSchema

  authorize(["Tech", "Accountant", "Admin"])

  def index(conn, _params) do
    json(
      conn,
      maintenance(conn).v1_list_techs(
        ClientSchema.new(conn.assigns.client_schema, conn.assigns.admin)
      )
    )
  end

  def show(conn, %{"id" => id}) do
    json(
      conn,
      maintenance(conn).v1_get_tech(
        ClientSchema.new(conn.assigns.client_schema, conn.assigns.admin),
        id
      )
    )
  end

  def update(conn, %{"id" => id, "tech" => params = %{}}) do
    with {:ok, _updated_tech} <-
           maintenance(conn).v1_update_tech(
             ClientSchema.new(conn.assigns.client_schema, conn.assigns.admin),
             id,
             params
           ) do
      json(conn, %{})
    else
      # TODO: when not found?
      {:error, error} -> json(conn, error)
    end
  end
end
