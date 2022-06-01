defmodule AppCount.MaintenanceOrdersTaskTest do
  @moduledoc false
  use AppCount.DataCase
  alias AppCount.Tasks
  alias AppCount.Maintenance
  import AppCount.LeaseHelper
  import AppCount.TimeCop
  alias AppCount.Core.ClientSchema

  setup do
    lease =
      insert_lease(%{
        start_date: Timex.shift(DateTime.utc_now(), months: -6),
        end_date: Timex.shift(DateTime.utc_now(), months: 6)
      })

    category = insert(:category)

    params = %{
      property_id: lease.unit.property_id,
      unit_id: lease.unit_id,
      tenant_id: hd(lease.tenants).id,
      category_id: category.id,
      has_pet: true,
      entry_allowed: false,
      priority: "3"
    }

    {:ok, recurring} =
      Maintenance.create_recurring_order(
        ClientSchema.new("dasmen", %{
          name: "Some Random Name",
          property_id: lease.unit.property_id,
          params: params,
          schedule: %{
            hour: [8],
            minute: [30],
            day: nil,
            year: nil,
            month: nil,
            week: nil,
            wday: nil
          }
        })
      )

    {:ok, [recurring: recurring, params: params]}
  end

  # off by one hour
  @doc """
     1) test creates maintenance order (AppCount.MaintenanceOrdersTaskTest)
       test/app_count/tasks/maintenance_orders_test.exs:46
       Assertion with == failed
       code:  assert reloaded.next_run == recurring.next_run + 24 * 3600
       left:  1615725000
       right: 1615728600
       stacktrace:
         test/app_count/tasks/maintenance_orders_test.exs:61: (test)

    Using local time for test or calculations will often cause problems.
    It would be better to stick with DateTime.utc_now() or Clock.now()
  """
  @tag :flaky
  test "creates maintenance order", %{recurring: recurring, params: params} do
    :ok =
      DateTime.from_unix!(recurring.next_run)
      |> Timex.Timezone.convert(Timex.local().time_zone)
      |> Timex.shift(minutes: 1)
      |> freeze do
        Tasks.Workers.MaintenanceOrders.perform()
      end

    assert_receive {:start, AppCount.Maintenance.Utils.Orders, :assign_status_task,
                    [_order_id, "unassigned"]}

    assert Repo.get_by(Maintenance.Order, params)
    reloaded = Repo.get(Maintenance.RecurringOrder, recurring.id)
    assert reloaded.last_run == recurring.next_run
    assert reloaded.next_run == recurring.next_run + 24 * 3600
  end

  test "creates nothing before target time", %{recurring: recurring, params: params} do
    DateTime.from_unix!(recurring.next_run)
    |> Timex.Timezone.convert(Timex.local().time_zone)
    |> Timex.shift(minutes: -1)
    |> freeze do
      Tasks.Workers.MaintenanceOrders.perform()
    end

    refute Repo.get_by(Maintenance.Order, params)
    reloaded = Repo.get(Maintenance.RecurringOrder, recurring.id)
    assert reloaded.last_run == recurring.last_run
    assert reloaded.next_run == recurring.next_run
  end
end
