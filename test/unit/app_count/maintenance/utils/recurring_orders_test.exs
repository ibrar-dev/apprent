defmodule AppCount.Maintenance.Utils.RecurringOrdersTest do
  use AppCount.DataCase
  import AppCount.TimeCop
  alias AppCount.Maintenance
  alias AppCount.Core.ClientSchema
  @moduletag :recurring_orders

  setup do
    admin = AppCount.UserHelper.new_admin()
    property = insert(:property)
    category = insert(:sub_category)
    {:ok, [admin: admin, property: property, category: category]}
  end

  test "creates recurring orders", %{admin: admin, property: property, category: category} do
    order_params = %{
      "note" => "This is a really dumb note.",
      "property_id" => property.id,
      "priority" => 1,
      "entry_allowed" => false,
      "has_pet" => true,
      "category_id" => category.id
    }

    params = %{
      "name" => "Recurring Order",
      "admin_id" => admin.id,
      "schedule" => %{
        "day" => nil,
        "hour" => [10],
        "wday" => [3, 4, 5, 6],
        "week" => nil,
        "year" => nil,
        "month" => nil,
        "minute" => [0]
      },
      "property_id" => property.id,
      "params" => order_params
    }

    # this is a Tuesday
    time =
      %Date{year: 2019, day: 1, month: 1}
      |> Timex.to_datetime()
      |> Timex.shift(hours: 12)

    first_ts =
      time
      |> Timex.shift(hours: 22)
      |> Timex.to_unix()

    freeze time do
      {:ok, order} = Maintenance.create_recurring_order(ClientSchema.new("dasmen", params))
      assert order.next_run == first_ts

      # When
      :ok = AppCount.Tasks.Workers.MaintenanceOrders.perform()

      refute_receive {:start, AppCount.Maintenance.Utils.Orders, :assign_status_task,
                      [_order_id, "unassigned"]}

      assert Repo.all(Maintenance.Order) == []
    end

    freeze Timex.shift(time, days: 3) do
      # When
      :ok = AppCount.Tasks.Workers.MaintenanceOrders.perform()

      assert_receive {:start, AppCount.Maintenance.Utils.Orders, :assign_status_task,
                      [_order_id, "unassigned"]}

      order =
        Maintenance.Order
        |> Repo.all()
        |> hd
        |> Repo.preload(:notes)

      assert order.property_id == property.id
      assert order.category_id
      assert order.has_pet
      refute order.entry_allowed

      # Performed in a Task, so it should be a separate test.
      # note = hd(order.notes)
      # assert note.admin_id == admin.id
      # assert note.text == "This is a really dumb note."
    end
  end
end
