defmodule AppCountWeb.API.EntityView do
  use AppCountWeb, :view

  def render("index.json", %{entities: entities}) do
    render_many(entities, __MODULE__, "entity.json")
  end

  def render("entity.json", %{entity: entity}) do
    %{
      id: entity.id,
      name: entity.name,
      resources: entity.resources,
      property_ids: entity.property_ids
    }
  end
end
