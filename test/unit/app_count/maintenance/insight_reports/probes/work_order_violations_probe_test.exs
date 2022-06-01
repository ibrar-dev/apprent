defmodule AppCount.Maintenance.InsightReports.WorkOrderViolationsProbeTest do
  use AppCount.ProbeCase
  alias AppCount.Maintenance.InsightReports.WorkOrderViolationsProbe

  describe "call/? a property with " do
    setup do
      builder =
        PropBuilder.new(:create)
        |> PropBuilder.add_property()

      ~M[builder]
    end

    test "no workorder has no violations", ~M[builder] do
      property =
        builder
        |> PropBuilder.get_requirement(:property)

      violations_count = WorkOrderViolationsProbe.call(property)

      assert 0 == violations_count
    end

    test "one workorder has no violations", ~M[builder] do
      property =
        builder
        |> PropBuilder.add_unit()
        |> PropBuilder.add_unit_category()
        |> PropBuilder.add_work_order_on_unit()
        |> PropBuilder.get_requirement(:property)

      violations_count = WorkOrderViolationsProbe.call(property)

      assert 0 == violations_count
    end

    test "one workorder has a Maintenance.Order violation", ~M[builder] do
      property =
        builder
        |> PropBuilder.add_unit()
        |> PropBuilder.add_unit_category()
        |> PropBuilder.add_work_order_on_unit(priority: 3)
        |> PropBuilder.get_requirement(:property)

      violations_count = WorkOrderViolationsProbe.call(property)

      assert 1 == violations_count
    end

    test "two workorders, only ONE has a Maintenance.Order violation", ~M[builder] do
      property =
        builder
        |> PropBuilder.add_unit()
        |> PropBuilder.add_unit_category()
        |> PropBuilder.add_work_order_on_unit(priority: 3)
        |> PropBuilder.add_work_order_on_unit(priority: 1)
        |> PropBuilder.get_requirement(:property)

      violations_count = WorkOrderViolationsProbe.call(property)

      assert 1 == violations_count
    end

    test "two workorders has TWO Maintenance.Order violations", ~M[builder] do
      property =
        builder
        |> PropBuilder.add_unit()
        |> PropBuilder.add_unit_category()
        |> PropBuilder.add_work_order_on_unit(priority: 3)
        |> PropBuilder.add_work_order_on_unit(priority: 3)
        |> PropBuilder.get_requirement(:property)

      violations_count = WorkOrderViolationsProbe.call(property)

      assert 2 == violations_count
    end

    test "one workorder has a Vendors.Order violation", ~M[builder] do
      property =
        builder
        |> PropBuilder.add_unit()
        |> PropBuilder.add_vendor_category()
        |> PropBuilder.add_vendor()
        |> PropBuilder.add_vendor_work_order(priority: 3)
        |> PropBuilder.get_requirement(:property)

      violations_count = WorkOrderViolationsProbe.call(property)

      assert 1 == violations_count
    end
  end
end
