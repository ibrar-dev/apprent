defmodule AppCount.Accounting.PaymentAnalyticsBoundary do
  @moduledoc """
  Boundary
  """
  alias AppCount.Core.DateTimeRange
  alias AppCount.Core.Clock
  alias AppCount.Accounting.PaymentAnalyticsRepo

  # Move slow functions into PaymentAnalyticsRepo
  def info_boxes_payment_analytics(property_ids, schema) when is_list(property_ids) do
    mtd_date_range = DateTimeRange.month_to_date()
    day_date_range = DateTimeRange.day_of(Clock.now())

    mtd_payments =
      PaymentAnalyticsRepo.get_payments_in_range(mtd_date_range, property_ids, schema)

    day_payments =
      PaymentAnalyticsRepo.get_payments_in_range(day_date_range, property_ids, schema)

    number_of_payments = %{
      day_of: length(day_payments),
      mtd: length(mtd_payments)
    }

    payments_amount = %{
      day_of: reduce_for_amount(day_payments),
      mtd: reduce_for_amount(mtd_payments)
    }

    # These should not be part of "payment analytics" but OPs wants them here...
    tenants_with_autopay =
      PaymentAnalyticsRepo.tenants_with_autopay(property_ids, schema)
      |> length()

    # These should not be part of "payment analytics" but OPs wants them here...
    tenants_with_no_login =
      PaymentAnalyticsRepo.tenants_with_no_login(property_ids, schema)
      |> length()

    %{
      number_of_payments: number_of_payments,
      payments_amount: payments_amount,
      tenants_with_autopay: tenants_with_autopay,
      tenants_with_no_login: tenants_with_no_login
    }
  end

  # To let the front end handle the data for the charts or not, that is the question.
  # This fails with multiple(5+) on prod.
  def charts_payment_analytics(property_ids, dates, schema) when is_list(property_ids) do
    dates =
      get_dates(dates)
      |> DateTimeRange.list_to_date_time_range()

    PaymentAnalyticsRepo.get_payments_in_range(dates, property_ids, schema)
  end

  def reduce_for_amount([]), do: 0

  def reduce_for_amount(payments) do
    payments
    |> Enum.reduce(Decimal.new(0), fn p, acc ->
      Decimal.add(acc, p.amount)
    end)
  end

  # Using AntD DateRangePicker will always return dates in this format.
  # Consider moving this parser into a single function in AppCount.Core so it does not need to be in multiple places.
  # Six months if no dates
  def get_dates(nil) do
    start_d =
      Timex.today()
      |> Timex.shift(months: -6)
      |> Timex.beginning_of_month()
      |> Timex.to_naive_datetime()

    end_d =
      Timex.today()
      |> Timex.to_naive_datetime()
      |> Timex.end_of_day()

    [start_d, end_d]
  end

  def get_dates(""), do: get_dates(nil)

  def get_dates(dates) do
    start_d =
      String.split(dates, ",")
      |> List.first()
      |> Timex.parse!("{YYYY}-{0M}-{0D}")
      |> Timex.to_naive_datetime()
      |> Timex.beginning_of_day()

    end_d =
      String.split(dates, ",")
      |> List.last()
      |> Timex.parse!("{YYYY}-{0M}-{0D}")
      |> Timex.to_naive_datetime()
      |> Timex.end_of_day()

    [start_d, end_d]
  end
end
