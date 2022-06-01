defmodule AppCountCom.AdminView do
  alias AppCount.Maintenance.InsightReports.InsightReportFormatter
  use AppCountCom, :view
  use AppCount.Decimal

  def datetime_display(datetime) do
    Timex.format!(datetime, "{M}/{D}/{YYYY} {h12}:{m} {AM}")
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

  def constructed_link(%{link_path: path}) when not is_nil(path) do
    constructed_link(path)
  end

  def constructed_link(path) when is_binary(path) do
    "#{root_url()}/#{path}"
  end

  def constructed_link(_datum) do
    "#{root_url()}/maintenance_reports"
  end

  def root_url() do
    AppCount.namespaced_url("administration")
  end

  def utc_convert(datetime) when is_binary(datetime) do
    Timex.parse!(datetime, "{RFC3339z}")
    |> utc_convert
  end

  def utc_convert(datetime) do
    tz = AppCount.current_time().time_zone

    Timex.Timezone.convert(datetime, tz)
    |> datetime_display
  end

  def number_to_currency(d) do
    formatted =
      d
      |> to_decimal()
      |> Decimal.to_float()
      |> :erlang.float_to_binary(decimals: 2)

    "$#{formatted}"
  end

  def get_all_approved(logs) do
    logs
    |> Enum.filter(&(&1["status"] == "Approved"))
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

  def payments_for(property_id, payments) do
    payments
    |> Enum.filter(&(&1.property_id == property_id))
  end
end
