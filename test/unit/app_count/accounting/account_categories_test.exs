defmodule AppCount.Accounting.AccountCategoriesTest do
  use AppCount.DataCase
  alias AppCount.Accounting
  alias AppCount.Repo
  alias AppCount.Accounting.Category
  alias AppCount.Core.ClientSchema

  @moduletag :account_categories

  setup do
    {:ok, cat: insert(:account_category)}
  end

  test "create account category works" do
    params = %{"name" => "new cat", "num" => 11_000_000, "max" => 11_999_999}
    Accounting.create_category(params)
    result = Accounting.account_tree()
    first = Enum.at(result, 1)
    assert length(result) == 4
    assert first.num == 11_000_000
    assert first.name == "new cat"
  end

  test "update account category works just name", %{cat: cat} do
    params = %{"name" => "Category 1"}
    Accounting.update_category(cat.id, params)
    result = Repo.get(Category, cat.id)
    assert result.name == "Category 1"
  end

  test "update account category works and re-arranges", %{cat: cat} do
    params = %{"num" => 50_000_000, "max" => 59_999_999}
    Accounting.update_category(cat.id, params)
    insert(:account_category, num: 11_000_000, max: 11_999_999, name: "New Category")
    new_list = Accounting.account_tree()
    result = Enum.at(new_list, 2)
    assert length(new_list) == 4
    assert result.num == 50_000_000
  end

  test "order works with accounts", %{} do
    schema = "dasmen"
    Accounting.create_category(%{num: 11_000_000, max: 11_999_999, name: "Cat2"})
    Accounting.create_category(%{num: 31_000_000, name: "Cat3", max: 31_999_999})
    Accounting.create_account(ClientSchema.new(schema, %{name: "acc1", num: 11_100_000}))
    Accounting.create_account(ClientSchema.new(schema, %{name: "acc2", num: 11_200_000}))
    Accounting.create_account(ClientSchema.new(schema, %{name: "acc3", num: 31_100_000}))
    result = Accounting.account_tree()
    assert length(result) == 9
    assert List.last(result).num == 31_999_999
    assert List.last(result).name == "Total Cat3"
  end

  test "depth works", %{} do
    Accounting.create_category(%{num: 11_000_000, name: "Cat2", max: 11_999_999})
    insert(:account, num: 11_500_000)
    result = Accounting.get_depth(11_500_000)
    assert result == 2
  end
end
