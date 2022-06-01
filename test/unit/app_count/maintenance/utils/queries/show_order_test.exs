defmodule AppCount.Maintenance.Utils.Queries.ShowOrderTest do
  use AppCount.DataCase
  alias AppCount.Maintenance.Utils.Queries
  alias AppCount.Core.ClientSchema

  @moduletag :queries_show_order

  setup do
    order = insert(:order)
    {:ok, order: order, admin: admin_with_access([order.property.id])}
  end

  test "show_order", %{order: order, admin: admin} do
    result = Queries.show_order(ClientSchema.new("dasmen", admin), order.id)

    assert result.category.id == order.category.id
    assert result.unit.id == order.unit.id
    assert result.tenant.id == order.tenant.id
    assert result.property.id == order.property.id
    assert result.status == order.status

    insert(:assignment, status: "in_progress", order: order)

    assert Queries.show_order(ClientSchema.new("dasmen", admin), order.id).status == "assigned"

    AppCount.Maintenance.update_order(
      order.id,
      ClientSchema.new("dasmen", %{"cancellation" => %{"some" => "map"}})
    )

    result = Queries.show_order(ClientSchema.new("dasmen", admin), order.id)
    assert result.status == "cancelled"
  end
end
