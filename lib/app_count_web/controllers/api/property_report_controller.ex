defmodule AppCountWeb.API.PropertyReportController do
  use AppCountWeb, :controller

  alias AppCount.Properties
  alias AppCount.Reports
  alias AppCount.Core.ClientSchema

  def index(
        conn,
        %{
          "move_outs" => _,
          "property_id" => property_id,
          "start_date" => start,
          "end_date" => end_date
        }
      ) do
    json(conn, Reports.move_outs_report(conn.assigns.admin, property_id, start, end_date))
  end

  def index(
        conn,
        %{
          "delinquency" => _,
          "filters" => filters,
          "property_id" => property_id,
          "date" => date,
          "ar" => ar,
          "download" => "excel"
        }
      ) do
    data = Reports.dq_report_excel(property_id, filters, ar, date)

    send_download(
      conn,
      {:binary, data},
      content_type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
      filename: "DQ Report#{date}.xlsx"
    )
  end

  def index(conn, %{"property_id" => property_id, "resident_directory" => _}) do
    json(conn, AppCount.Reports.ResidentDirectory.resident_directory(property_id))
  end

  def index(conn, %{"delinquency" => _, "property_id" => property_id, "date" => date}) do
    json(conn, Reports.delinquency_report(property_id, date))
  end

  def index(
        conn,
        %{
          "admin_id" => admin_id,
          "admin_payments_and_charges" => _,
          "start_date" => start_date,
          "end_date" => end_date
        }
      ) do
    json(conn, Reports.admin_payments_and_charges(admin_id, start_date, end_date))
  end

  def index(
        conn,
        %{
          "payment_report" => _,
          "property_id" => property_id,
          "start_date" => start_date,
          "end_date" => end_date
        }
      ) do
    json(
      conn,
      Reports.find_applicants_report(conn.assigns.admin, property_id, start_date, end_date)
    )
  end

  def index(conn, %{
        "box_score" => _,
        "property_id" => property_id,
        "type" => type,
        "dates" => dates
      }) do
    json(conn, Reports.box_score(conn.assigns.admin, property_id, dates, type))
  end

  # UNTESTED
  def index(conn, %{"unit_status" => _, "property_id" => property_id} = params) do
    end_date = params["end_date"]

    box_score =
      if(end_date) do
        AppCount.Reports.Queries.UnitStatus.fetch_box_score(
          property_id,
          Date.from_iso8601!(end_date)
        )
      else
        AppCount.Reports.Queries.UnitStatus.fetch_box_score(property_id)
      end

    json(conn, box_score)
  end

  def index(conn, %{"mtm" => _, "property_id" => property_id}) do
    json(conn, Reports.mtm_report(conn.assigns.admin, property_id))
  end

  def index(conn, %{
        "rent_roll" => _,
        "property_id" => property_id,
        "date" => date,
        "download" => "excel"
      }) do
    data = AppCount.Exports.RentRoll.rent_roll_excel(conn.assigns.admin, property_id, date)

    send_download(
      conn,
      {:binary, data},
      content_type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
      filename: "RentRollExport.xlsx"
    )
  end

  def index(conn, %{"rent_roll" => _, "property_id" => property_id, "date" => date}) do
    json(conn, Reports.rent_roll(conn.assigns.admin, property_id, date))
  end

  def index(conn, %{"collection" => _, "property_id" => property_id}) do
    json(conn, Reports.collection_report(property_id, nil))
  end

  def index(conn, %{"open_make_ready_report" => _, "date" => date}) do
    json(conn, Reports.open_make_ready_report(ClientSchema.new(conn.assigns.admin), date))
  end

  def index(conn, %{"property_metrics" => _, "start_date" => start_date, "end_date" => end_date}) do
    json(
      conn,
      Reports.property_metrics(
        conn.assigns.admin,
        start_date,
        end_date
      )
    )
  end

  def index(conn, %{"daily_deposit" => _, "property_id" => property_id, "date" => date}) do
    json(conn, Reports.daily_deposit(ClientSchema.new(conn.assigns.admin), property_id, date))
  end

  def index(conn, %{"aging" => _, "property_id" => property_id} = p) do
    json(conn, Reports.aging_report(conn.assigns.admin, property_id, p["date"]))
  end

  def index(conn, %{"gpr" => _} = params) do
    %{"date" => date, "post_month" => post_month, "property_id" => property_id} = params

    if params["excel"] do
      filename = "Gross Potential Rent #{date}.xlsx"
      send_xlsx(conn, Reports.gross_potential_rent_excel(property_id, date, post_month), filename)
    else
      json(conn, Reports.gross_potential_rent(property_id, date, post_month))
    end
  end

  def index(conn, %{"expiring_leases" => _, "property_id" => property_id, "date" => date}) do
    json(conn, Reports.expiring_leases_report(property_id, date))
  end

  def index(conn, %{"property_ids" => ids}) do
    property_ids = String.split(ids, ",")

    json(
      conn,
      Properties.specific_property_report(
        ClientSchema.new(conn.assigns.client_schema, property_ids)
      )
    )
  end

  def index(conn, _) do
    json(conn, Properties.property_report(ClientSchema.new(conn.assigns.admin)))
  end

  defp send_xlsx(conn, data, filename) do
    send_download(
      conn,
      {:binary, data},
      content_type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
      filename: filename
    )
  end
end
