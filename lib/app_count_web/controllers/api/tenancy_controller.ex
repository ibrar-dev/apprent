defmodule AppCountWeb.API.TenancyController do
  use AppCountWeb, :controller

  authorize(["Admin", "Agent", "Accountant"], index: ["Tech", "Admin", "Agent"])

  def index(conn, %{"property_id" => property_id}) do
    json(conn, tenant_boundary(conn).list_tenancies(conn.assigns.admin, property_id))
  end

  def update(conn, %{"id" => id, "tenancy" => params}) do
    tenant_boundary(conn).update_tenancy(id, params)
    json(conn, %{})
  end

  def show(conn, %{"id" => id}) do
    if data = tenant_boundary(conn).get_tenancy(conn.assigns.admin, id) do
      json(conn, data)
    else
      conn
      |> put_status(404)
      |> json(%{errors: ["tenancy with id:#{id} not found"]})
    end
  end
end
