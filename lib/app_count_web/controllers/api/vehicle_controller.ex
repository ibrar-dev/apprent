defmodule AppCountWeb.API.VehicleController do
  use AppCountWeb, :controller
  alias AppCount.Tenants

  def create(conn, %{"vehicle" => params}) do
    Tenants.create_vehicle(params)
    json(conn, %{})
  end

  def update(conn, %{"id" => id, "vehicle" => params}) do
    Tenants.update_vehicle(id, params)
    json(conn, %{})
  end

  def delete(conn, %{"id" => id}) do
    Tenants.delete_vehicle(conn.assigns.admin, id)
    json(conn, %{})
  end
end
