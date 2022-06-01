defmodule HebrewDate do
  @unix_epoch %{year: 5730, month: 10, day: 23}

  defdelegate mod(a, b), to: Integer
  defdelegate floor_div(a, b), to: Integer

  def hebrew_date(gregorian_date) do
    gregorian_date
    |> days_since_unix_epoch
    |> increment(@unix_epoch)
  end

  def increment(0, date), do: date

  def increment(num_days, %{day: 29, month: 6} = date) do
    increment(num_days - 1, Map.merge(date, %{day: 1, month: 7, year: date.year + 1}))
  end

  def increment(num_days, %{} = date) do
    next_date =
      if is_last_day_of_month(date) do
        Map.merge(date, %{day: 1, month: increment_month(date)})
      else
        Map.put(date, :day, date.day + 1)
      end

    increment(num_days - 1, next_date)
  end

  def increment_month(%{month: month, year: year}) do
    cond do
      month < 12 -> month + 1
      month == 12 && hebrew_leap_year?(year) -> 13
      true -> 1
    end
  end

  def is_last_day_of_month(%{day: day, month: month, year: year}) do
    num_days = days_in_hebrew_year(year)

    day ==
      cond do
        Enum.member?([2, 4, 6, 10, 13], month) -> 29
        month == 8 && mod(num_days, 10) != 5 -> 29
        month == 9 && mod(num_days, 10) == 3 -> 29
        month == 12 && !hebrew_leap_year?(year) -> 29
        true -> 30
      end
  end

  def days_since_unix_epoch(date) do
    floor_div(Timex.to_unix(date), 24 * 3600)
  end

  def hebrew_leap_year?(year) do
    mod(7 * year + 1, 19) < 7
  end

  def days_in_hebrew_year(year) do
    hebrew_calendar_elapsed_days(year + 1) - hebrew_calendar_elapsed_days(year)
  end

  def hebrew_calendar_elapsed_days(year) do
    last_year = year - 1
    # Months in complete cycles so far
    # Regular months in this cycle
    # Leap months this cycle
    months_elapsed =
      235 * floor_div(last_year, 19) +
        12 * mod(last_year, 19) +
        floor_div(7 * mod(last_year, 19) + 1, 19)

    parts_elapsed = 204 + 793 * mod(months_elapsed, 1080)

    hours_elapsed =
      5 + 12 * months_elapsed + 793 * floor_div(months_elapsed, 1080) +
        floor_div(parts_elapsed, 1080)

    conjunction_day = 1 + 29 * months_elapsed + floor_div(hours_elapsed, 24)
    conjunction_parts = 1080 * mod(hours_elapsed, 24) + mod(parts_elapsed, 1080)

    factor =
      cond do
        conjunction_parts >= 19_440 ->
          1

        mod(conjunction_day, 7) == 2 && conjunction_parts >= 9924 && hebrew_leap_year?(year) ->
          1

        mod(conjunction_day, 7) == 1 && conjunction_parts >= 16_789 &&
            hebrew_leap_year?(last_year) ->
          1

        true ->
          0
      end

    # If Rosh Hashana would occur on Sunday, Wednesday, or Friday
    # then postpone it one more day
    postpone =
      if Enum.member?([0, 3, 5], mod(conjunction_day + factor, 7)) do
        1
      else
        0
      end

    conjunction_day + factor + postpone
  end
end
