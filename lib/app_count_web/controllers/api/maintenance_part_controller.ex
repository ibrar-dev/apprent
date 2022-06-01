defmodule AppCountWeb.API.MaintenancePartController do
  use AppCountWeb, :controller
  require Logger

  def create(conn, params) do
    maintenance(conn).create_part(params)
    json(conn, %{})
  end

  def update(conn, %{"id" => id, "part" => part}) do
    maintenance(conn).update_part(id, part)
    json(conn, %{})
  end

  def update(conn, %{"parts" => parts}) do
    maintenance(conn).update_parts(parts)
    json(conn, %{})
  end

  def delete(conn, %{"id" => id}) do
    maintenance(conn).remove_part(id)
    json(conn, %{})
  end
end
