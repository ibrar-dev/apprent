defmodule AppCount.Maintenance.Utils.V1.CategoriesTest do
  use AppCount.DataCase
  alias AppCount.Maintenance.Utils.V1.Categories

  setup do
    [_builder, parent_category, category] =
      PropBuilder.new(:create)
      |> PropBuilder.add_parent_category(%{name: "parent"})
      |> PropBuilder.add_category(%{name: "child"})
      |> PropBuilder.get([:parent_category, :category])

    %{parent_category: parent_category, category: category}
  end

  test "list_categories/1", %{parent_category: parent_category, category: category} do
    client = AppCount.Public.get_client_by_schema("dasmen")

    result = Categories.list_categories(client.client_schema)

    expected_parent = %{id: parent_category.id, name: "parent", parent: nil}
    expected_child = %{id: category.id, name: "child", parent: expected_parent}

    assert(Enum.count(result) == 2)
    assert(Enum.member?(result, expected_parent))
    assert(Enum.member?(result, expected_child))
  end
end
