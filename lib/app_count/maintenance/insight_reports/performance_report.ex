defmodule AppCount.Maintenance.InsightReports.PerformanceReport do
  alias AppCount.Maintenance.InsightReports.PerformanceScore
  alias AppCount.Maintenance.InsightReports.ProbeContext
  alias AppCount.Core.DateTimeRange

  def generate_stats(
        %AppCount.Properties.Property{} = property,
        %DateTimeRange{} = date_range
      ) do
    score =
      ProbeContext.load(property, date_range)
      |> PerformanceScore.readings()
      |> PerformanceScore.from_readings()

    score
  end
end
