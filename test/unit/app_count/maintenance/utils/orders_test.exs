defmodule AppCount.Maintenance.Utils.OrdersTest do
  use AppCount.DataCase
  alias AppCount.Maintenance.Utils.Orders
  alias AppCount.Core.ClientSchema

  setup do
    admin = AppCount.UserHelper.new_admin()
    tech = insert(:tech)
    property = insert(:property)

    params = %{
      "note" => "This is a really dumb note.",
      "property_id" => property.id,
      "priority" => 1,
      "entry_allowed" => true,
      "has_pet" => true,
      "category_id" => insert(:sub_category).id
    }

    ~M[admin,  tech,  property, params]
  end

  test "creates orders and assign", ~M[admin,  tech, params] do
    params = Map.put(params, "tech", tech.id)
    client = AppCount.Public.get_client_by_schema("dasmen")

    {:ok, order} = Orders.create_order(admin.id, ClientSchema.new(client.client_schema, params))

    # We sleep bc the note creation was moved into a Task.async call, Test fails otherwirs.
    Process.sleep(500)

    # Then
    new_order =
      AppCount.Repo.get(AppCount.Maintenance.Order, order.id, prefix: client.client_schema)
      |> AppCount.Repo.preload(:notes)

    assert String.length(new_order.ticket) == 10

    # Move to a new test of the sub-task
    ## assert new_order.status == "assigned"
    ## assert Enum.at(new_order.notes, 0).text == "This is a really dumb note."
    ## assert Enum.at(new_order.notes, 0).admin_id == admin.id
  end

  test "creates orders and unassign", ~M[admin, params] do
    client = AppCount.Public.get_client_by_schema("dasmen")

    {:ok, order} = Orders.create_order(admin.id, ClientSchema.new(client.client_schema, params))

    order_id = order.id

    assert_receive {:start, AppCount.Maintenance.Utils.Orders, :assign_status_task,
                    [^order_id, "unassigned"]}

    # Then
    new_order =
      AppCount.Repo.get(AppCount.Maintenance.Order, order.id)
      |> AppCount.Repo.preload(:notes)

    # Move status check into a test for Maintenance.Utils.Orders.assign_status_task/2
    # assert new_order.status == "unassigned"
    assert String.length(new_order.ticket) == 10
    #
    # Performed in a Task, so it should be a separate test.
    ## assert Enum.at(new_order.notes, 0).text == "This is a really dumb note."
    ## assert Enum.at(new_order.notes, 0).admin_id == admin.id
  end
end
