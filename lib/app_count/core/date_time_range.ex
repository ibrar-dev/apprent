defmodule AppCount.Core.DateTimeRange do
  alias AppCount.Core.DateTimeRange
  alias AppCount.Core.Clock

  defstruct [:from, :to]

  def year_to_date do
    from = Clock.now() |> Timex.beginning_of_year()
    to = Clock.now() |> Timex.end_of_day()
    %DateTimeRange{from: from, to: to}
  end

  def month_to_date do
    from = Clock.now() |> Timex.beginning_of_month()
    to = Clock.now() |> Timex.end_of_day()
    %DateTimeRange{from: from, to: to}
  end

  def new(%DateTime{} = from, %DateTime{} = to) do
    if Timex.before?(to, from) do
      raise "invalid range, 'from' must preceed 'to'. from:#{inspect(from)} to:#{inspect(to)}"
    end

    %DateTimeRange{from: from, to: to}
  end

  def day_of(%Date{} = day) do
    {:ok, from} = DateTime.new(day, ~T[00:00:00], "Etc/UTC")
    {:ok, to} = DateTime.new(day, ~T[23:59:59], "Etc/UTC")
    %DateTimeRange{from: from, to: to}
  end

  def day_of(%DateTime{} = datetime) do
    from = datetime |> Timex.beginning_of_day()
    to = datetime |> Timex.end_of_day()
    %DateTimeRange{from: from, to: to}
  end

  def today() do
    DateTime.utc_now()
    |> day_of()
  end

  def within?(%DateTimeRange{from: from, to: to}, %DateTime{} = instant) do
    equal_to_edge =
      DateTime.compare(from, instant) == :eq ||
        DateTime.compare(to, instant) == :eq

    inside =
      DateTime.compare(from, instant) == :lt &&
        DateTime.compare(to, instant) == :gt

    inside || equal_to_edge
  end

  # 24 hours ago from right now to right now
  def last24hours(now \\ DateTime.utc_now()) do
    from = Timex.shift(now, days: -1)
    %DateTimeRange{from: from, to: now}
  end

  def last12hours(now \\ DateTime.utc_now()) do
    from = Timex.shift(now, hours: -12)
    %DateTimeRange{from: from, to: now}
  end

  def to_list(%DateTimeRange{from: from, to: to}) do
    [from, to]
  end

  # Start of yesterday to end of yesterday
  def yesterday do
    today() |> shift(hours: -24)
  end

  def shift(%DateTimeRange{from: from, to: to}, options) do
    %DateTimeRange{
      from: from |> Timex.shift(options),
      to: to |> Timex.shift(options)
    }
  end

  def last30days(ending \\ DateTime.utc_now()) do
    to = ending |> Timex.end_of_day()

    from =
      ending
      |> Timex.beginning_of_day()
      |> Timex.shift(days: -30)

    %DateTimeRange{from: from, to: to}
  end

  def next_year(ending \\ DateTime.utc_now()) do
    from = ending |> Timex.end_of_day()

    to =
      ending
      |> Timex.beginning_of_day()
      |> Timex.shift(days: 366)

    %DateTimeRange{from: from, to: to}
  end

  def date_range(%DateTimeRange{from: from, to: to}) do
    Date.range(
      DateTime.to_date(from),
      DateTime.to_date(to)
    )
  end

  # The front end oftens sends dates up in a List.
  def list_to_date_time_range([from, to]) do
    %DateTimeRange{from: from, to: to}
  end
end
