defmodule AppCount.Core.Clock do
  @moduledoc """
  AppCount Specific DateTime createing and shifting
  Clock is stopped in the test environment
  """

  @seconds_in_a_minute 60
  @seconds_in_an_hour 60 * @seconds_in_a_minute
  @seconds_in_a_day 24 * @seconds_in_an_hour

  @tz_utc "Etc/UTC"
  @tz_nyc "America/New_York"

  def tz_utc, do: @tz_utc
  def tz_nyc, do: @tz_nyc

  def now() do
    DateTime.utc_now()
    |> DateTime.truncate(:second)
  end

  def now({seconds, :seconds}) do
    now()
    |> DateTime.add(seconds, :second)
  end

  def now({minutes, :minutes}) do
    seconds = minutes * @seconds_in_a_minute
    now({seconds, :seconds})
  end

  def now({hours, :hours}) do
    seconds = hours * @seconds_in_an_hour
    now({seconds, :seconds})
  end

  def now({days, :days}) do
    seconds = days * @seconds_in_a_day
    now({seconds, :seconds})
  end

  def today() do
    now() |> DateTime.to_date()
  end

  def today({days, :days}) do
    today()
    |> Date.add(days)
  end

  def date_from_iso8601!(iso8601_string) do
    iso8601_string
    |> Date.from_iso8601!()
  end

  # beginning of day
  def bod(%Date{} = date, zone \\ @tz_utc) do
    {:ok, naive} = NaiveDateTime.new(date, ~T[00:00:00])
    {:ok, datetime} = DateTime.from_naive(naive, zone)
    datetime
  end

  # end of day
  def eod(%Date{} = date, zone \\ @tz_utc) do
    {:ok, naive} = NaiveDateTime.new(date, ~T[23:59:59])
    {:ok, datetime} = DateTime.from_naive(naive, zone)
    datetime
  end

  def to_nyc(%DateTime{} = datetime) do
    to_zone(datetime, tz_nyc())
  end

  def to_utc(%NaiveDateTime{} = naive) do
    naive |> DateTime.from_naive!(@tz_utc)
  end

  def to_utc(%DateTime{} = datetime) do
    datetime |> to_zone(@tz_utc)
  end

  def to_zone(%DateTime{} = datetime, timezone) do
    datetime |> DateTime.shift_zone!(timezone)
  end

  # All NaiveDateTimes in the system are assumed UTC
  def to_zone(%NaiveDateTime{} = datetime, timezone) do
    dt = DateTime.from_naive!(datetime, @tz_utc)
    to_zone(dt, timezone)
  end

  def less_than(%Date{} = date1, date2) do
    Date.compare(date1, date2) == :lt
  end

  def less_than(%DateTime{} = datetime1, datetime2) do
    DateTime.compare(datetime1, datetime2) == :lt
  end

  def greater_than(%Date{} = date1, date2) do
    Date.compare(date1, date2) == :gt
  end

  def greater_than(%DateTime{} = date1, date2) do
    DateTime.compare(date1, date2) == :gt
  end

  def equal(%Date{} = date1, date2) do
    Date.compare(date1, date2) == :eq
  end

  def equal(%DateTime{} = datetime1, datetime2) do
    DateTime.compare(datetime1, datetime2) == :eq
  end

  def less_than_or_equal(%Date{} = date1, date2) do
    less_than(date1, date2) ||
      equal(date1, date2)
  end

  def less_than_or_equal(%DateTime{} = datetime1, datetime2) do
    less_than(datetime1, datetime2) ||
      equal(datetime1, datetime2)
  end

  def beginning_of_month do
    today()
    |> Timex.beginning_of_month()
  end

  def thirty_days do
    today()
    |> Timex.shift(days: 30)
  end
end
