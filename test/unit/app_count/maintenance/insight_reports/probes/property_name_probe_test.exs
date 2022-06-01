defmodule AppCount.Maintenance.InsightReports.PropertyNameProbeTest do
  use AppCount.ProbeCase
  alias AppCount.Maintenance.InsightReports.PropertyNameProbe

  test "insight_item" do
    daily_context = %ProbeContext{
      input: %{
        property: %{name: "Faulty Towers"}
      }
    }

    insight_item = PropertyNameProbe.insight_item(daily_context)
    assert insight_item.reading.measure == {"Faulty Towers", :text}
  end
end
