defmodule AppCount.Maintenance.InsightReports.UnitCountProbeTest do
  use AppCount.ProbeCase
  alias AppCount.Maintenance.InsightReports.UnitCountProbe

  test "one" do
    daily_context = %ProbeContext{
      input: %{
        unit_tallies: %{
          ready: 3,
          not_ready: 4
        }
      }
    }

    insight_item = UnitCountProbe.insight_item(daily_context)
    assert insight_item.reading.measure == {7, :count}
  end
end
