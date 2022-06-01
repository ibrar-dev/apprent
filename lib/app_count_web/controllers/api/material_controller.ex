defmodule AppCountWeb.API.MaterialController do
  use AppCountWeb, :controller
  alias AppCount.Materials

  def index(conn, %{"search" => params}) do
    json(conn, Materials.search_materials(params))
  end

  def create(conn, %{"material" => params}) do
    Materials.create_material(params)
    json(conn, %{})
  end

  def show(conn, %{"id" => id}) do
    json(conn, Materials.get_material(id))
  end

  def update(conn, %{"id" => id, "material" => params}) do
    Materials.update_material(id, params)
    json(conn, %{})
  end

  def delete(conn, %{"id" => id}) do
    Materials.delete_material(id)
    json(conn, %{})
  end
end
