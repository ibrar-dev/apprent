defmodule AppCount.OrderTest do
  use AppCount.DataCase
  alias AppCount.Maintenance.Order
  alias AppCount.Support.AppTime

  setup do
    times =
      AppTime.new()
      |> AppTime.plus(:plus_ten, minutes: 10)
      |> AppTime.plus(:plus_five, minutes: 5)
      |> AppTime.plus(:now, minutes: 0)
      |> AppTime.times()

    order = insert(:order)
    a1 = insert(:assignment, order: order, inserted_at: times.plus_ten)
    a2 = insert(:assignment, order: order, inserted_at: times.plus_five)
    a3 = insert(:assignment, order: order, inserted_at: times.now)
    o = AppCount.Repo.preload(order, :assignments)
    {:ok, [order: o, assignments: [a1, a2, a3]]}
  end

  def new_order() do
    Order.new(
      category_id: 10,
      property_id: 12,
      has_pet: false,
      entry_allowed: true,
      priority: 1,
      ticket: "ticket"
    )
  end

  test "Order.current_assignment", context do
    assert Order.current_assignment(context.order).id == Enum.at(context.assignments, 0).id
  end

  test "create" do
    assert new_order()
  end

  test "changeset" do
    order = new_order()

    changeset = Order.changeset(order, %{allow_sms: true})
    assert changeset.valid?
  end

  test "url/1" do
    assert Order.url(99) == "http://residents.localhost:4001/order/99"
  end
end
