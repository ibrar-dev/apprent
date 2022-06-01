defmodule AppCountWeb.API.CategoryView do
  use AppCountWeb, :view

  def render("index.json", %{categories: categories}) do
    render_many(categories, __MODULE__, "category.json")
  end

  def render("category.json", %{category: %{children: children} = category}) do
    %{
      id: category.id,
      name: category.name,
      children: Enum.map(children, &render("category.json", %{category: &1}))
    }
  end

  def render("category.json", %{category: category}) do
    %{
      id: category["id"],
      name: category["name"]
    }
  end
end
