defmodule AppCount.Maintenance.Utils.V1.Categories do
  alias AppCount.Maintenance.Category
  alias AppCount.Maintenance.CategoryRepo

  def list_categories(client_schema) do
    CategoryRepo.list(client_schema)
    |> Enum.map(&needed_data(&1))
  end

  defp needed_data(%Category{} = category) do
    %{
      id: category.id,
      name: category.name,
      parent: needed_data(category.parent)
    }
  end

  defp needed_data(_record) do
    nil
  end
end
