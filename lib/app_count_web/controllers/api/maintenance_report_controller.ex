defmodule AppCountWeb.API.MaintenanceReportController do
  use AppCountWeb, :controller
  alias AppCount.Maintenance
  alias AppCount.Core.ClientSchema

  def index(conn, %{"daily_report" => _}) do
    json(conn, Maintenance.info_for_daily_report(conn.assigns.admin))
  end

  # Generate the maintenance performance score for a single property
  def index(conn, %{"property" => property_id, "type" => "performance_score"}) do
    score =
      property_id
      |> String.to_integer()
      |> report_boundary(conn).performance_report()

    data = %{current: score}

    json(conn, data)
  end

  def index(conn, %{"admin_id" => id}) do
    json(conn, Maintenance.property_stats_query_by_admin_six_months(id))
  end

  def index(conn, %{"six_months_stats" => _, "property_id" => property_id}) do
    json(
      conn,
      Maintenance.property_stats_query_by_admin_six_months(
        ClientSchema.new(conn.assigns.client_schema, conn.assigns.admin.id),
        property_id
      )
    )
  end

  def index(conn, %{"startDate" => start_date, "endDate" => end_date, "completed" => _}) do
    json(
      conn,
      Maintenance.admin_completed(
        conn.assigns.admin,
        Timex.parse!(start_date, "{YYYY}-{0M}-{D}"),
        Timex.parse!(end_date, "{YYYY}-{0M}-{D}")
      )
    )
  end

  def index(conn, %{"startDate" => start_date, "endDate" => end_date, "categories" => _}) do
    json(
      conn,
      Maintenance.admin_categories(
        conn.assigns.admin,
        Timex.parse!(start_date, "{YYYY}-{0M}-{D}"),
        Timex.parse!(end_date, "{YYYY}-{0M}-{D}")
      )
    )
  end

  def index(conn, %{"startDate" => start_date, "endDate" => end_date, "categoriesCompleted" => _}) do
    json(
      conn,
      Maintenance.admin_categories_completed(
        conn.assigns.admin,
        Timex.parse!(start_date, "{YYYY}-{0M}-{D}"),
        Timex.parse!(end_date, "{YYYY}-{0M}-{D}")
      )
    )
  end

  def index(conn, %{"startDate" => start_date, "endDate" => end_date, "makeReadyReport" => _}) do
    json(
      conn,
      Maintenance.make_ready_report(
        conn.assigns.admin,
        Timex.parse!(start_date, "{YYYY}-{0M}-{D}"),
        Timex.parse!(end_date, "{YYYY}-{0M}-{D}")
      )
    )
  end

  def index(conn, %{"property_metrics" => _, "startDate" => start_date, "endDate" => end_date}) do
    json(
      conn,
      AppCount.Reports.property_metrics(
        ClientSchema.new(conn.assigns.client_schema, conn.assigns.admin),
        start_date,
        end_date
      )
    )
  end

  def index(conn, %{"dates" => dates, "properties" => property_ids, "type" => type}) do
    split_property_ids = String.split(property_ids, ",")

    json(
      conn,
      Maintenance.get_analytics(
        ClientSchema.new(conn.assigns.client_schema, dates),
        ClientSchema.new(conn.assigns.client_schema, split_property_ids),
        type
      )
    )
  end

  def index(conn, _params) do
    property_report =
      conn.assigns.admin
      |> ClientSchema.new()
      |> Maintenance.property_report()

    unit_report =
      conn.assigns.admin
      |> ClientSchema.new()
      |> Maintenance.unit_report()

    json(conn, %{
      properties: property_report,
      units: unit_report
    })
  end

  def create(conn, %{"params" => params, "techReport" => _}) do
    data = Maintenance.tech_report(ClientSchema.new(conn.assigns.client_schema, params))

    json(conn, data)
  end

  def create(conn, %{"notes" => notes, "admin_ids" => admins}) do
    Maintenance.send_daily_report(notes, admins, conn.assigns.admin)
    json(conn, %{})
  end
end
