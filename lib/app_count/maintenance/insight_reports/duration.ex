defmodule AppCount.Maintenance.InsightReports.Duration do
  # TODO: rename to AppCount.Core.Duration
  alias AppCount.Maintenance.InsightReports.Duration
  defstruct [:seconds]

  @minute 60
  @hour 60 * @minute
  @day 24 * @hour
  @week 7 * @day
  @month 30 * @day
  @year 365 * @day

  def new({seconds, :seconds}) when is_number(seconds) do
    %Duration{seconds: seconds}
  end

  def new({days, :days}) when is_number(days) do
    seconds = days * @day
    %Duration{seconds: seconds}
  end

  def to_days(%Duration{seconds: seconds}) when is_number(seconds) do
    to_days({seconds, :seconds})
  end

  def to_days({seconds, :seconds}) when is_number(seconds) do
    result =
      (seconds / @day)
      |> Float.round(2)

    {result, :days}
  end

  def to_seconds(%Duration{seconds: seconds}) when is_number(seconds) do
    {seconds, :seconds}
  end

  def to_seconds({days, :days}) when is_number(days) do
    seconds = days * @day
    {seconds, :seconds}
  end

  def display(%Duration{} = duration) do
    duration
    |> to_seconds()
    |> display()
  end

  def display({value, _unit}) when is_nil(value) do
    "N/A"
  end

  def display({value, _unit}) when is_binary(value) do
    "N/A"
  end

  # Convert float value to integers -- we can lose a fraction of a second
  def display({value, :seconds}) when is_float(value) do
    display({trunc(value), :seconds})
  end

  def display({value, :seconds}) when value >= @year do
    "> 1 year"
  end

  # "7 months, 3 weeks"
  def display({value, :seconds}) when value >= @month do
    whole_months = div(value, @month)
    just_weeks = rem(value, @month)

    whole_weeks = div(just_weeks, @week)

    month_text = time_string(whole_months, "month")
    week_text = time_string(whole_weeks, "week")

    full_string(week_text, month_text)
  end

  # "3 weeks, 4 days"
  def display({value, :seconds}) when value >= @week do
    whole_weeks = div(value, @week)
    just_days = rem(value, @week)

    whole_days = div(just_days, @day)

    week_text = time_string(whole_weeks, "week")
    day_text = time_string(whole_days, "day")

    full_string(day_text, week_text)
  end

  # "3 days, 12 hours"
  def display({value, :seconds}) when is_number(value) and value >= @day do
    whole_days = div(value, @day)
    just_hours = rem(value, @day)

    whole_hours = div(just_hours, @hour)

    day_text = time_string(whole_days, "day")
    hour_text = time_string(whole_hours, "hour")

    full_string(hour_text, day_text)
  end

  # "4 hours, 3 minutes"
  def display({value, :seconds}) when is_number(value) and value >= @hour do
    whole_hours = div(value, @hour)
    just_minutes = rem(value, @hour)

    whole_minutes = div(just_minutes, @minute)

    hour_text = time_string(whole_hours, "hour")
    minute_text = time_string(whole_minutes, "minute")

    full_string(minute_text, hour_text)
  end

  # "17 minutes"
  def display({value, :seconds}) when is_number(value) do
    minutes = div(value, @minute)

    time_string(minutes, "minute")
  end

  # Given "3 days" and "4 months" (the latter should be of the bigger unit),
  # produces a "4 months, 3 days" string.
  #
  # Given "0 days" and "4 months", produces just "4 months"
  def full_string(str_1, str_2) do
    cond do
      str_1 =~ ~r{^0} ->
        str_2

      true ->
        "#{str_2}, #{str_1}"
    end
  end

  # Given 1, "day" -> "1 day"
  # Given 3, "day" -> "3 days"
  def time_string(value, unit) when is_number(value) do
    if value == 1 do
      "#{value} #{unit}"
    else
      "#{value} #{unit}s"
    end
  end
end
