defmodule AppCountCom.PropertyView do
  use AppCount.Decimal
  use AppCountCom, :view
  alias AppCount.Maintenance.InsightReports.InsightReportFormatter

  def readable_time(minutes) do
    Timex.now()
    |> Timex.beginning_of_day()
    |> Timex.shift(minutes: minutes)
    |> Timex.format!("{h12}:{m}{AM}")
  end

  def readable_date(date) do
    date
    |> Timex.format!("{WDfull}, {Mfull} {D} {YYYY}")
  end

  # Given something like this, convert to something a little more pleasant:
  #
  # #DateTime<2020-08-20 17:00:00-04:00 EDT US/Eastern>
  #
  # August 20, 2020 - 5:00 pm
  #
  # See https://hexdocs.pm/timex/Timex.Format.DateTime.Formatters.Strftime.html
  # for more information on formatting this string
  def readable_datetime(datetime) do
    Timex.format!(datetime, "%B %d, %Y - %I:%M %p", :strftime)
  end

  # We have a number of different ways to express data in our maintenance
  # reports, and we would like to format differently based on those data types.
  def formatted_insight_string(datum) do
    InsightReportFormatter.format(datum)
  end

  def number_to_currency(%Decimal{} = d) do
    formatted =
      d
      |> Decimal.to_float()
      |> :erlang.float_to_binary(decimals: 2)

    "$#{formatted}"
  end

  def number_to_currency(d) do
    formatted =
      d
      |> to_decimal()
      |> Decimal.to_float()
      |> :erlang.float_to_binary(decimals: 2)

    "$#{formatted}"
  end

  def get_payee(params) do
    case params["payee_id"] do
      nil ->
        "N/A"

      _ ->
        payee = AppCount.Accounting.get_payee(params["payee_id"])
        payee.name
    end
  end

  def get_amount(params) do
    case params["amount"] do
      nil -> "N/A"
      _ -> number_to_currency(params["amount"])
    end
  end

  def get_description(params) do
    case params["description"] do
      nil -> "N/A"
      _ -> params["description"]
    end
  end

  def recent_notes(admin_notes) do
    admin_notes
    |> Enum.reverse()
    |> Enum.take(3)
  end

  def get_status_of_logs(logs) do
    logs
    |> Enum.filter(&(&1["status"] == "Pending"))
    |> Enum.uniq_by(& &1["admin_id"])
    |> Enum.map(fn l ->
      status =
        Enum.filter(logs, fn log -> log["admin_id"] == l["admin_id"] end)
        |> List.first()

      Map.merge(l, %{"status" => status["status"]})
    end)
  end

  def all_approved(logs) do
    logs
    |> Enum.all?(&(&1["status"] == "Approved"))
  end

  def get_all_approved(logs) do
    logs
    |> Enum.filter(&(&1["status"] == "Approved"))
  end

  def get_color(status) do
    case status do
      "Approved" -> "green"
      "Declined" -> "red"
      _ -> ""
    end
  end
end
