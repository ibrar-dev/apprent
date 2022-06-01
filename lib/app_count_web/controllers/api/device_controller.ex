defmodule AppCountWeb.API.DeviceController do
  use AppCountWeb, :controller
  alias AppCount.Admins
  alias AppCount.Admins.Auth.Devices

  authorize(["Super Admin"])

  def index(conn, _params) do
    json(conn, Admins.list_devices(conn.assigns.client_schema))
  end

  def create(conn, %{"device" => %{"name" => name}}) do
    json(conn, %{cert: Devices.register_device(name)})
  end

  def update(conn, %{"id" => id, "device" => params}) do
    Admins.update_device(id, params)
    json(conn, %{})
  end

  def delete(conn, %{"id" => id}) do
    Admins.delete_device(id)
    json(conn, %{})
  end
end
