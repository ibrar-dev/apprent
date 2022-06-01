defmodule AppCount.Maintenance.ReportBoundary do
  @moduledoc """
  Boundary
  """
  alias AppCount.Maintenance.InsightReports.PerformanceScore
  alias AppCount.Maintenance.InsightReports.ProbeContext
  alias AppCount.Core.ClientSchema

  def performance_report(property_id) when is_number(property_id) do
    date_range = AppCount.Core.DateTimeRange.last24hours()

    score =
      ClientSchema.new("dasmen", property_id)
      |> AppCount.Properties.get_property()
      |> ProbeContext.load(date_range)
      |> PerformanceScore.readings()
      |> PerformanceScore.from_readings()
      |> PerformanceScore.scale()

    score
  end
end
