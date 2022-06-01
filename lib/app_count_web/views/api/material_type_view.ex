defmodule AppCountWeb.API.MaterialTypeView do
  use AppCountWeb, :view

  def render("index.json", %{types: types}) do
    render_many(types, __MODULE__, "material_type.json")
  end

  def render("material_type.json", %{material_type: type}) do
    %{id: type.id, name: type.name}
  end
end
