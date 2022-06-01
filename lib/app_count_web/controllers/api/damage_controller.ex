defmodule AppCountWeb.API.DamageController do
  use AppCountWeb, :controller
  alias AppCount.Settings

  authorize(["Super Admin"], index: ["Regional", "Admin", "Agent", "Tech"])

  def index(conn, _params) do
    json(conn, Settings.list_damages())
  end

  def create(conn, %{"damage" => params}) do
    Settings.create_damage(params)
    json(conn, %{})
  end

  def update(conn, %{"id" => id, "damage" => params}) do
    Settings.update_damage(id, params)
    json(conn, %{})
  end

  def delete(conn, %{"id" => id}) do
    Settings.delete_damage(id)
    json(conn, %{})
  end
end
