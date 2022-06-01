defmodule AppCountWeb.API.DeviceAuthController do
  use AppCountWeb, :controller
  alias AppCount.Admins.Auth.Devices

  def create(conn, %{"name" => name}) do
    json(conn, Devices.register_device(name))
  end
end
