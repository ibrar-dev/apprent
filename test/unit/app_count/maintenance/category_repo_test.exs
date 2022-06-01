defmodule AppCount.Maintenance.CategoryRepoTest do
  use AppCount.DataCase
  alias AppCount.Maintenance.CategoryRepo

  setup do
    [_builder, parent_category, category] =
      PropBuilder.new(:create)
      |> PropBuilder.add_parent_category(%{name: "parent"})
      |> PropBuilder.add_category(%{name: "child"})
      |> PropBuilder.get([:parent_category, :category])

    %{parent_category: parent_category, category: category}
  end

  test "list/0", %{parent_category: parent_category, category: category} do
    client = AppCount.Public.get_client_by_schema("dasmen")

    result = CategoryRepo.list(client.client_schema)

    assert(Enum.count(result) == 2)
    assert(Enum.find(result, &(&1.id == parent_category.id)))
    assert(Enum.find(result, &(&1.id == category.id)))
  end
end
