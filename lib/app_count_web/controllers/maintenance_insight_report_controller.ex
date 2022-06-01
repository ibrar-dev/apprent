defmodule AppCountWeb.MaintenanceInsightReportController do
  alias AppCount.Maintenance.InsightReports
  alias AppCount.Maintenance.InsightReport
  use AppCountWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html", %{title: "Maintenance Insight Reports"})
  end

  def show(conn, %{"id" => id}) do
    report = InsightReports.fetch(id)

    if report do
      issued_at = InsightReports.formatted_time(report)
      template_name = InsightReport.template_name(report)

      render(conn, template_name, %{
        title: "Maintenance Insight Report",
        report: report,
        issued_at: issued_at
      })
    else
      conn
      |> put_status(404)
      |> redirect(to: Routes.maintenance_insight_report_path(conn, :index))
    end
  end
end
