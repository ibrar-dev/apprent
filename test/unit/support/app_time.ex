defmodule AppCount.Support.AppTime do
  # used to create times for testing
  alias AppCount.Support.AppTime
  defstruct now: nil, times: %{}

  def new(now \\ DateTime.utc_now()) do
    %__MODULE__{now: now}
  end

  def plus_to_naive(%AppTime{} = apptime, name, opts) do
    plus(apptime, name, opts)
    |> to_naive(name)
  end

  def plus_to_date(%AppTime{} = apptime, name, opts) do
    plus(apptime, name, opts)
    |> to_date(name)
  end

  def plus(%AppTime{times: times, now: now} = apptime, name, opts) do
    time = Timex.shift(now, opts)

    times =
      times
      |> Map.put(name, time)

    %{apptime | times: times}
  end

  def end_of_day(%AppTime{times: times, now: now} = apptime) do
    end_of_day = Timex.end_of_day(now) |> DateTime.truncate(:second)

    times =
      times
      |> Map.put(:end_of_day, end_of_day)

    %{apptime | times: times}
  end

  def start_of_year(%AppTime{times: times, now: now} = apptime) do
    start_of_year = Timex.beginning_of_year(now) |> DateTime.truncate(:second)

    times =
      times
      |> Map.put(:start_of_year, start_of_year)

    %{apptime | times: times}
  end

  def start_of_month(%AppTime{times: times, now: now} = apptime) do
    start_of_month = Timex.beginning_of_month(now) |> DateTime.truncate(:second)

    times =
      times
      |> Map.put(:start_of_month, start_of_month)

    %{apptime | times: times}
  end

  def times(%AppTime{times: times}) do
    times
  end

  def to_date(%AppTime{times: times} = apptime, name) do
    converted = Map.get(times, name) |> Timex.to_date()
    times = Map.put(times, name, converted)
    %{apptime | times: times}
  end

  def to_naive(%AppTime{times: times} = apptime, name) do
    converted =
      Map.get(times, name)
      |> Timex.to_naive_datetime()
      |> NaiveDateTime.truncate(:second)

    times = Map.put(times, name, converted)
    %{apptime | times: times}
  end

  def to_naive(%DateTime{} = date_time) do
    date_time
    |> Timex.to_naive_datetime()
    |> NaiveDateTime.truncate(:second)
  end

  def to_naive(times) when is_map(times) do
    times
    |> Enum.reduce(
      %{},
      fn {name, datetime}, acc -> Map.put(acc, name, to_naive(datetime)) end
    )
  end
end
