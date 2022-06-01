defmodule AppCount.Maintenance.InsightReports.PerformanceReportTest do
  use AppCount.ProbeCase
  alias AppCount.Maintenance.InsightReports.PerformanceReport

  describe "generate_stats/2" do
    setup do
      builder =
        PropBuilder.new(:create)
        |> PropBuilder.add_property()
        |> PropBuilder.add_unit()
        |> PropBuilder.add_unit_category()
        |> PropBuilder.add_tech()
        |> PropBuilder.add_work_order_on_unit()

      date_range_today = DateTimeRange.today()

      ~M[builder, date_range_today]
    end

    test "one", ~M[builder, date_range_today] do
      property =
        builder
        |> PropBuilder.get_requirement(:property)

      expected_score = %AppCount.Maintenance.InsightReports.PerformanceScore{
        callbacks: 7.5,
        make_ready_percent: 0.0,
        make_ready_turnaround: 0.0,
        make_ready_utilization: 0.0,
        property_name: property.name,
        ratings: 0,
        violations: 7.5,
        work_order_saturation: 0,
        work_order_turnaround: 15
      }

      # When
      score = PerformanceReport.generate_stats(property, date_range_today)

      assert score == expected_score
    end
  end
end
