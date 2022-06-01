defmodule AppCount.Maintenance.InsightReports.WorkOrdersSubmittedProbeTest do
  use AppCount.ProbeCase
  alias AppCount.Maintenance.InsightReports.WorkOrdersSubmittedProbe

  test "insight_item", ~M[  today_range, property] do
    daily_context = ProbeContext.new([], [], property, today_range)

    # When
    insight_item = WorkOrdersSubmittedProbe.insight_item(daily_context)

    assert insight_item.comments == []
  end
end
