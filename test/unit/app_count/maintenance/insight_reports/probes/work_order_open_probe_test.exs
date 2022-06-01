defmodule AppCount.Maintenance.InsightReports.WorkOrderOpenProbeTest do
  use AppCount.ProbeCase
  alias AppCount.Maintenance.InsightReports.WorkOrderOpenProbe

  test "insight_item", ~M[  today_range, property] do
    daily_context = ProbeContext.new([], [], property, today_range)

    # When
    insight_item = WorkOrderOpenProbe.insight_item(daily_context)

    assert insight_item.comments == []
  end
end
