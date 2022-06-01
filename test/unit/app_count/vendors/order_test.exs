defmodule AppCount.Vendors.OrderTest do
  use AppCount.VendorsCase

  test "create" do
    assert new_order()
  end

  test "changeset" do
    order = new_order()

    changeset = Order.changeset(order, %{status: "unassigned"})
    assert changeset.valid?
  end

  test "store in db" do
    order = new_order()

    result =
      order
      |> Order.changeset(%{status: "completed"})
      |> Repo.insert()

    assert {:ok, stored_order} = result
    assert stored_order.id
    assert stored_order.inserted_at
    assert stored_order.status == "completed"
  end
end
