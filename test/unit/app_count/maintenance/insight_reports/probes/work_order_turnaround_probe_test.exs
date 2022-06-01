defmodule AppCount.Maintenance.InsightReports.WorkOrderTurnaroundProbeTest do
  use AppCount.DataCase
  alias AppCount.Maintenance.OrderRepo
  alias AppCount.Maintenance.InsightReports.WorkOrderTurnaroundProbe
  alias AppCount.Maintenance.InsightReports.ProbeContext

  @five_hours_in_seconds 60 * 60 * 5
  @five_mins_in_seconds 60 * 5

  describe "reading/1" do
    setup do
      today_range = AppCount.Core.DateTimeRange.today()

      times =
        AppTime.new()
        |> AppTime.plus(:now, days: 0)
        |> AppTime.plus_to_naive(:five_mins_ago, minutes: -5)
        |> AppTime.plus_to_naive(:five_hours_ago, hours: -5)
        |> AppTime.plus_to_naive(:two_days_ago, days: -2)
        |> AppTime.plus_to_naive(:three_days_ago, days: -3)
        |> AppTime.times()

      builder =
        PropBuilder.new(:create)
        |> PropBuilder.add_property()
        |> PropBuilder.add_unit()
        |> PropBuilder.add_parent_category()
        |> PropBuilder.add_category()
        |> PropBuilder.add_tech()

      ~M[today_range, builder, times]
    end

    test "calculates with a completed (today) work order", ~M[today_range, builder, times] do
      property = PropBuilder.get_requirement(builder, :property)
      admin = Factory.admin_with_access([property.id])

      start_time = times.five_mins_ago
      client = AppCount.Public.get_client_by_schema("dasmen")

      order =
        builder
        |> PropBuilder.create_unit_work_order(start_time, admin, client.client_schema)
        |> PropBuilder.get_requirement(:work_order)

      order = OrderRepo.get_aggregate(order.id)

      context = %ProbeContext{input: %{orders: [order], date_range: today_range}}

      _expected = %AppCount.Maintenance.Reading{
        display: "duration",
        link_path: "orders?selected_properties=",
        measure: {@five_mins_in_seconds, :seconds},
        name: :work_order_turnaround,
        title: "Average Open Ticket Duration",
        value: @five_mins_in_seconds
      }

      # When
      reading = WorkOrderTurnaroundProbe.reading(context)

      {actual_in_seconds, :seconds} = reading.measure
      assert_in_delta actual_in_seconds, @five_mins_in_seconds, 2
    end
  end

  describe "call/1" do
    setup do
      today_range = AppCount.Core.DateTimeRange.today()

      times =
        AppTime.new()
        |> AppTime.plus(:now, days: 0)
        |> AppTime.plus_to_naive(:five_mins_ago, minutes: -5)
        |> AppTime.plus_to_naive(:five_hours_ago, hours: -5)
        |> AppTime.plus_to_naive(:two_days_ago, days: -2)
        |> AppTime.plus_to_naive(:three_days_ago, days: -3)
        |> AppTime.times()

      builder =
        PropBuilder.new(:create)
        |> PropBuilder.add_property()
        |> PropBuilder.add_unit()
        |> PropBuilder.add_parent_category()
        |> PropBuilder.add_category()
        |> PropBuilder.add_tech()

      ~M[today_range, builder, times]
    end

    test "calculates with no work orders", ~M[today_range] do
      orders = []
      duration_in_seconds = WorkOrderTurnaroundProbe.call(orders, today_range)

      assert duration_in_seconds == 0
    end

    test "calculates with an unassigned work order", ~M[today_range, builder, times] do
      # 5 hours ago, submittable as NaiveDateTime so we can use it as the
      # :inserted_at value for our work order
      order_submitted = times.five_hours_ago

      builder =
        builder
        |> PropBuilder.add_work_order_on_unit(inserted_at: order_submitted)

      order = PropBuilder.get_requirement(builder, :work_order)

      order = OrderRepo.get_aggregate(order.id)

      assert Timex.compare(order_submitted, order.inserted_at) == 0

      # When
      duration_in_seconds = WorkOrderTurnaroundProbe.call([order], today_range)

      assert_in_delta duration_in_seconds, @five_hours_in_seconds, 1
    end

    test "calculates with an assigned work order", ~M[builder, today_range, times] do
      order_submitted = times.five_hours_ago

      builder =
        builder
        |> PropBuilder.add_work_order_on_unit(inserted_at: order_submitted, status: "assigned")

      order = PropBuilder.get_requirement(builder, :work_order)
      order = OrderRepo.get_aggregate(order.id)

      assert Timex.compare(order_submitted, order.inserted_at) == 0

      # When
      duration_in_seconds = WorkOrderTurnaroundProbe.call([order], today_range)

      assert_in_delta duration_in_seconds, @five_hours_in_seconds, 1
    end

    test "calculates with a completed (today) work order", ~M[today_range, builder, times] do
      property = PropBuilder.get_requirement(builder, :property)
      admin = Factory.admin_with_access([property.id])

      start_time = times.five_mins_ago
      client = AppCount.Public.get_client_by_schema("dasmen")

      order =
        builder
        |> PropBuilder.create_unit_work_order(start_time, admin, client.client_schema)
        |> PropBuilder.get_requirement(:work_order)

      order = OrderRepo.get_aggregate(order.id)

      # When
      duration_in_seconds = WorkOrderTurnaroundProbe.call([order], today_range)

      assert_in_delta duration_in_seconds, @five_mins_in_seconds, 1
    end

    test "ignores out-of-range completed work orders", ~M[today_range, builder, times] do
      property = PropBuilder.get_requirement(builder, :property)
      admin = Factory.admin_with_access([property.id])

      start_time = times.three_days_ago
      completed_at = times.two_days_ago
      client = AppCount.Public.get_client_by_schema("dasmen")

      order =
        builder
        |> PropBuilder.create_unit_work_order(start_time, admin, client.client_schema,
          completed_at: completed_at
        )
        |> PropBuilder.get_requirement(:work_order)

      order = OrderRepo.get_aggregate(order.id)

      # When
      duration_in_seconds = WorkOrderTurnaroundProbe.call([order], today_range)

      # The work order was out of range, and thus not counted
      assert duration_in_seconds == 0
    end

    test "ignores cancelled work orders", ~M[today_range, builder] do
      builder =
        builder
        |> PropBuilder.add_work_order_on_unit(status: "cancelled")

      order = PropBuilder.get_requirement(builder, :work_order)
      order = OrderRepo.get_aggregate(order.id)

      duration_in_seconds = WorkOrderTurnaroundProbe.call([order], today_range)

      assert duration_in_seconds == 0
    end

    test "ignores make-ready work orders", ~M[today_range, builder, times] do
      property = PropBuilder.get_requirement(builder, :property)
      admin = Factory.admin_with_access([property.id])

      start_time = times.three_days_ago
      client = AppCount.Public.get_client_by_schema("dasmen")

      builder =
        builder
        |> PropBuilder.add_parent_category(name: "Make Ready")
        |> PropBuilder.add_category()
        |> PropBuilder.create_unit_work_order(start_time, admin, client.client_schema)

      order = PropBuilder.get_requirement(builder, :work_order)
      order = OrderRepo.get_aggregate(order.id)

      duration_in_seconds = WorkOrderTurnaroundProbe.call([order], today_range)

      assert duration_in_seconds == 0
    end
  end
end
