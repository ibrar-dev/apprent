defmodule AppCount.Jobs.Scheduler do
  alias AppCount.Jobs.Schedule
  import AppCount, only: [current_time: 0]

  def run_in(job, time) do
    target_time =
      current_time()
      |> Timex.shift(minutes: time)

    %{
      schedule: Map.take(target_time, [:year, :month, :day, :hour, :minute])
    }
    |> Map.merge(job)

    # |> Jobs.create_job()
  end

  def next_ts(%Schedule{} = job, time \\ nil) do
    case next_scheduled(job, time) do
      nil -> nil
      date -> Timex.to_unix(date)
    end
  end

  def next_scheduled(%Schedule{} = job, nil) do
    current =
      current_time()
      |> Timex.shift(minutes: 1)
      |> Map.put(:second, 0)

    scroll(current, job, job)
  end

  def next_scheduled(%Schedule{} = job, time) do
    time
    |> Timex.shift(minutes: 1)
    |> scroll(job, job)
  end

  defp scroll(time, %Schedule{year: year} = job, original_job) when is_list(year) do
    case next_value(time.year, year) do
      {:next, _} ->
        nil

      {:current, val} ->
        if time.year < val do
          time
          |> Map.merge(%{year: val, month: 1, day: 1, hour: 0, minute: 0})
        else
          time
        end
        |> scroll(Map.put(job, :year, nil), original_job)
    end
  end

  defp scroll(time, %Schedule{month: month} = job, original_job) when is_list(month) do
    case next_value(time.month, month) do
      {:next, val} ->
        Timex.shift(time, years: 1)
        |> Map.merge(%{month: val, day: 1, hour: 0, minute: 0})
        |> scroll(original_job, original_job)

      {:current, val} ->
        if time.month < val do
          Map.merge(time, %{month: val, day: 1, hour: 0, minute: 0})
        else
          time
        end
        |> scroll(Map.put(job, :month, nil), original_job)
    end
  end

  defp scroll(time, %Schedule{wday: wday} = job, original_job) when is_list(wday) do
    current_weekday = Timex.weekday(time)

    case next_value(current_weekday, wday) do
      {:next, val} ->
        Timex.shift(time, days: val - current_weekday + 7)
        |> Timex.beginning_of_day()
        |> scroll(original_job, original_job)

      {:current, val} when val == current_weekday ->
        scroll(time, Map.put(job, :wday, nil), original_job)

      {:current, val} ->
        Timex.shift(time, days: val - current_weekday)
        |> Timex.beginning_of_day()
        |> scroll(Map.put(job, :wday, nil), original_job)
    end
  end

  defp scroll(time, %Schedule{week: week} = job, original_job) when is_list(week) do
    case Enum.find(week, &(weekday_ordinal(time) == &1)) do
      nil ->
        Timex.shift(time, days: 7)
        |> Timex.beginning_of_week()
        |> scroll(original_job, original_job)

      _ ->
        scroll(time, Map.put(job, :week, nil), original_job)
    end
  end

  # If we have a "days of the month" arg in our scheduler, we want to set up for
  # that day of the month.
  #
  # One thing we handle here is the possibility that the job is scheduled for,
  # say, the 31st, and some months do not have that many days. In that case, we
  # run on the last day of the month instead.
  defp scroll(time, %Schedule{day: day} = job, original_job) when is_list(day) do
    case next_value(time.day, day) do
      {:next, val} ->
        new_time = Timex.shift(time, months: 1)
        val = adjust_for_end_of_month(new_time, val)

        new_time
        |> Map.merge(%{day: val, hour: 0, minute: 0})
        |> scroll(original_job, original_job)

      {:current, val} ->
        val = adjust_for_end_of_month(time, val)

        if time.day < val do
          Map.merge(time, %{day: val, hour: 0, minute: 0})
        else
          time
        end
        |> scroll(Map.put(job, :day, nil), original_job)
    end
  end

  defp scroll(time, %Schedule{hour: hour} = job, original_job) when is_list(hour) do
    case next_value(time.hour, hour) do
      {:next, val} ->
        Timex.shift(time, days: 1)
        |> Map.merge(%{hour: val, minute: 0})
        |> scroll(original_job, original_job)

      {:current, val} ->
        Map.put(time, :hour, val)

        if time.hour < val do
          Map.merge(time, %{hour: val, minute: 0})
        else
          time
        end
        |> scroll(Map.put(job, :hour, nil), original_job)
    end
  end

  defp scroll(time, %Schedule{minute: minute} = job, original_job) when is_list(minute) do
    case next_value(time.minute, minute) do
      {:next, val} ->
        Timex.shift(time, hours: 1)
        |> Map.put(:minute, val)
        |> scroll(original_job, original_job)

      {:current, val} ->
        Map.put(time, :minute, val)
        |> scroll(Map.put(job, :minute, nil), original_job)
    end
  end

  defp scroll(time, _, _), do: time

  # Timestamp is a DateTime, day is an int (likely 1..31) indicating a day of
  # the month. If the number is >28, then we possibly adjust for end-of-month by
  # backtracking to the actual end of the month.
  defp adjust_for_end_of_month(timestamp, day) do
    last_of_the_month = Timex.end_of_month(timestamp.year, timestamp.month).day

    min(day, last_of_the_month)
  end

  defp next_value(n, list) do
    sorted = Enum.sort(list)

    case Enum.find(sorted, &(&1 >= n)) do
      nil -> {:next, Enum.at(sorted, 0)}
      val -> {:current, val}
    end
  end

  defp weekday_ordinal(time, ordinal \\ 1) do
    last_week = Timex.shift(time, days: -7)

    if last_week.month == time.month do
      weekday_ordinal(last_week, ordinal + 1)
    else
      ordinal
    end
  end
end
