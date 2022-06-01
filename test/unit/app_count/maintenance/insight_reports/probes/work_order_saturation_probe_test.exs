defmodule AppCount.Maintenance.InsightReports.WorkOrderSaturationProbeTest do
  use AppCount.ProbeCase
  alias AppCount.Maintenance.InsightReports.WorkOrderSaturationProbe
  alias AppCount.VendorsCase.Helper
  alias AppCount.Core.ClientSchema

  test "insight_item", ~M[  today_range, property] do
    daily_context =
      ProbeContext.input_map()
      |> ProbeContext.new(property, today_range)

    # When
    insight_item = WorkOrderSaturationProbe.insight_item(daily_context)
    [comment | _] = insight_item.comments
    assert comment =~ ~r[job keeping work orders low!]
  end

  describe "call/? a property with " do
    setup do
      builder =
        PropBuilder.new(:create)
        |> PropBuilder.add_property()

      ~M[builder]
    end

    test "zero work orders and zero units has 0% saturation", ~M[builder] do
      property =
        builder
        |> PropBuilder.get_requirement(:property)

      open_orders =
        AppCount.Vendors.OrderRepo.currently_open(ClientSchema.new("dasmen", property.id))

      open_vendor_orders = []

      result = WorkOrderSaturationProbe.call(property, open_orders, open_vendor_orders)

      assert {0.0, 0, :percent} = result
    end

    test "zero work orders and ONE unit has 0% saturation", ~M[builder] do
      property =
        builder
        |> PropBuilder.add_unit()
        |> PropBuilder.get_requirement(:property)

      open_orders =
        AppCount.Vendors.OrderRepo.currently_open(ClientSchema.new("dasmen", property.id))

      open_vendor_orders = []

      result = WorkOrderSaturationProbe.call(property, open_orders, open_vendor_orders)

      assert {0.0, 0, :percent} = result
    end

    test "ONE work orders and ONE unit has 100% saturation", ~M[builder] do
      property =
        builder
        |> PropBuilder.add_unit()
        |> PropBuilder.add_unit_category()
        |> PropBuilder.add_work_order_on_unit()
        |> PropBuilder.get_requirement(:property)

      property = AppCount.Properties.PropertyRepo.get_aggregate(property.id)

      open_orders =
        AppCount.Maintenance.OrderRepo.currently_open(ClientSchema.new("dasmen", property.id))

      open_vendor_orders = []

      result = WorkOrderSaturationProbe.call(property, open_orders, open_vendor_orders)

      assert {100.0, 1, :percent} = result
    end

    test "ONE work orders and TWO unit has 50% saturation", ~M[builder] do
      property =
        builder
        |> PropBuilder.add_unit()
        |> PropBuilder.add_unit_category()
        |> PropBuilder.add_work_order_on_unit()
        |> PropBuilder.add_unit()
        |> PropBuilder.get_requirement(:property)

      property = AppCount.Properties.PropertyRepo.get_aggregate(property.id)

      open_orders =
        AppCount.Maintenance.OrderRepo.currently_open(ClientSchema.new("dasmen", property.id))

      open_vendor_orders = []

      result = WorkOrderSaturationProbe.call(property, open_orders, open_vendor_orders)

      assert {50.0, 1, :percent} = result
    end

    test "ONE work orders and FOUR unit has 25% saturation", ~M[builder] do
      property =
        builder
        |> PropBuilder.add_unit()
        |> PropBuilder.add_unit_category()
        |> PropBuilder.add_work_order_on_unit()
        |> PropBuilder.add_unit()
        |> PropBuilder.add_unit()
        |> PropBuilder.add_unit()
        |> PropBuilder.get_requirement(:property)

      property = AppCount.Properties.PropertyRepo.get_aggregate(property.id)

      open_orders =
        AppCount.Maintenance.OrderRepo.currently_open(ClientSchema.new("dasmen", property.id))

      open_vendor_orders = []

      result = WorkOrderSaturationProbe.call(property, open_orders, open_vendor_orders)

      assert {25.0, 1, :percent} = result
    end

    test "TWO work orders (1-maint, 1-vendor) and FOUR unit has 50% saturation", ~M[builder] do
      vendor_order = Helper.new_order()

      property =
        builder
        |> PropBuilder.add_unit()
        |> PropBuilder.add_unit_category()
        |> PropBuilder.add_work_order_on_unit()
        |> PropBuilder.add_unit()
        |> PropBuilder.add_unit()
        |> PropBuilder.add_unit()
        |> PropBuilder.get_requirement(:property)

      property = AppCount.Properties.PropertyRepo.get_aggregate(property.id)

      open_orders =
        AppCount.Maintenance.OrderRepo.currently_open(ClientSchema.new("dasmen", property.id))

      open_vendor_orders = [vendor_order]

      result = WorkOrderSaturationProbe.call(property, open_orders, open_vendor_orders)

      assert {50.0, 1, :percent} = result
    end
  end
end
