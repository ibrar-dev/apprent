defmodule AppCountWeb.API.MaterialTypeController do
  use AppCountWeb, :controller
  alias AppCount.Materials

  def index(conn, _params) do
    render(conn, "index.json", %{types: Materials.list_material_types()})
  end

  def create(conn, %{"type" => params}) do
    Materials.create_material_type(params)
    json(conn, %{})
  end
end
