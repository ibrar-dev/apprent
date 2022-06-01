defmodule AppCountWeb.API.PackageController do
  use AppCountWeb, :controller
  alias AppCount.Properties

  authorize(["Admin", "Agent", "Tech"])

  def index(conn, %{"property_ids" => property_ids}) when byte_size(property_ids) > 0 do
    json(
      conn,
      Properties.list_packages(
        conn.assigns.user,
        String.split(property_ids, ",")
      )
    )
  end

  def index(conn, _params) do
    json(conn, Properties.list_packages(conn.assigns.user))
  end

  def create(conn, %{"pack" => params}) do
    try do
      params
      |> Map.put("admin", conn.assigns.user.name)
      |> Properties.create_package()

      json(conn, %{})
    rescue
      e in RuntimeError ->
        message = e.message
        json(conn, %{error: message})
    end
  end

  def update(conn, %{"id" => id, "pack" => params}) do
    Properties.update_package(id, params)
    json(conn, %{})
  end

  def delete(conn, %{"id" => id}) do
    Properties.delete_package(id)
    json(conn, %{})
  end
end
