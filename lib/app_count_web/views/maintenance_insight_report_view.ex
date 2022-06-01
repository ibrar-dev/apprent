defmodule AppCountWeb.MaintenanceInsightReportView do
  use AppCountWeb, :view
  alias AppCount.Maintenance.InsightReports.InsightReportFormatter

  def formatted_insight_string(datum) do
    InsightReportFormatter.format(datum)
  end

  def constructed_path(%{link_path: path}) when not is_nil(path) do
    "/#{path}"
  end

  def constructed_path(_) do
    "/maintenance_reports"
  end
end
