defmodule AppCount.Maintenance.InsightReports.WorkOrderRatingProbeTest do
  use AppCount.ProbeCase
  alias AppCount.Maintenance.InsightReports.WorkOrderRatingProbe

  test "reading with nil returns zero" do
    probe_context = %ProbeContext{input: %{average_maintenance_rating: nil}}

    # When
    reading = WorkOrderRatingProbe.reading(probe_context)

    assert reading.value == 0
  end
end
