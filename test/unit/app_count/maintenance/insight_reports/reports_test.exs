defmodule AppCount.Maintenance.InsightReports.ReportsTest do
  alias AppCount.Maintenance.InsightReports.Reports
  use AppCount.DataCase

  describe "generate_daily_report/2" do
    setup do
      property =
        PropBuilder.new(:create)
        |> PropBuilder.add_property()
        |> PropBuilder.get_requirement(:property)

      cutoff =
        Timex.now()
        |> Timex.beginning_of_day()
        |> Timex.set(hour: 17)

      ~M[property, cutoff]
    end

    test "generates and saves", ~M[property, cutoff] do
      assert {:ok, report} = Reports.generate_daily_report(property, cutoff)

      # We should be accurate down to at least the minute
      assert Timex.compare(report.end_time, cutoff, :minute) == 0
      assert report.type == "daily"
      assert report.version == 1
    end
  end
end
