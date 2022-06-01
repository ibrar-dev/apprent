defmodule AppCount.Maintenance.OrderRepoTest do
  use AppCount.DataCase
  alias AppCount.Maintenance.OrderRepo
  alias AppCount.Core.ClientSchema

  setup do
    order = insert(:order)
    ~M[order]
  end

  describe "order in DB" do
    test "get order from id", ~M[order] do
      assert OrderRepo.get(order.id)
    end

    test "get_aggregate()", ~M[order] do
      full_order = OrderRepo.get_aggregate(order.id)
      assert Ecto.assoc_loaded?(full_order.category)
      assert Ecto.assoc_loaded?(full_order.property)
    end
  end

  describe "get_aggregate_by_property/1" do
    test "returns with an order" do
      order = insert(:order)
      property = order.property

      orders = OrderRepo.get_aggregate_by_property(ClientSchema.new("dasmen", property.id))

      assert length(orders) == 1

      assert order.id in Enum.map(orders, fn o -> o.id end)
    end

    test "does not get cancelled orders" do
      order = insert(:order, status: "cancelled")

      property = order.property

      orders = OrderRepo.get_aggregate_by_property(ClientSchema.new("dasmen", property.id))

      assert Enum.empty?(orders)
    end
  end
end
