defmodule AppCount.Maintenance.InsightReports.WorkOrderCallbacksProbeTest do
  use AppCount.ProbeCase
  alias AppCount.Maintenance.InsightReports.WorkOrderCallbacksProbe

  describe "call/? a property with " do
    test "no callbacks" do
      # When
      callback_assignments = []
      assignments_with_callbacks = WorkOrderCallbacksProbe.call(callback_assignments)

      assert assignments_with_callbacks == []
    end

    test "One maintenance assignment had a callback ", ~M[ assignments] do
      callback_assignments = [assignments.one]
      # When
      found_assignments = WorkOrderCallbacksProbe.call(callback_assignments)

      assert length(found_assignments) == 1
      assert found_assignments == [assignments.one]
    end

    test "insight_item", ~M[  today_range, property] do
      callback_assignments = []

      daily_context =
        ProbeContext.input_map(callback_assignments: callback_assignments)
        |> ProbeContext.new(property, today_range)

      # When
      insight_item = WorkOrderCallbacksProbe.insight_item(daily_context)

      assert insight_item.comments == []
    end
  end
end
