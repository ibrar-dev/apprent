defmodule AppCount.Maintenance.InsightReports.WorkOrderCompletedProbeTest do
  use AppCount.ProbeCase
  alias AppCount.Maintenance.InsightReports.WorkOrderCompletedProbe

  test "insight_item", ~M[  today_range, property] do
    daily_context = ProbeContext.new([], [], property, today_range)

    # When
    insight_item = WorkOrderCompletedProbe.insight_item(daily_context)

    assert insight_item.comments == []
  end
end
