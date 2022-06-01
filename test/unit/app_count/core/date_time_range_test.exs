defmodule AppCount.Core.DateTimeRangeTest do
  use AppCount.Case, async: true
  alias AppCount.Core.DateTimeRange
  alias AppCount.Support.AppTime
  alias AppCount.Core.Clock

  describe "date_range" do
    setup do
      times = %{
        now: ~U[2020-11-05 00:00:00Z],
        five_days: ~U[2020-11-09 00:00:00Z]
      }

      ~M[times]
    end

    test "five days", ~M[times] do
      datetime_range = DateTimeRange.new(times.now, times.five_days)

      # When
      date_range = DateTimeRange.date_range(datetime_range)

      assert Enum.count(date_range) == 5
      assert date_range.first == ~D[2020-11-05]
      assert date_range.last == ~D[2020-11-09]
    end

    test "one day" do
      date = ~D[2020-11-05]
      datetime_range = DateTimeRange.day_of(date)
      # When
      date_range = DateTimeRange.date_range(datetime_range)
      # Then

      assert Enum.count(date_range) == 1
      assert date_range.first == ~D[2020-11-05]
      assert date_range.last == ~D[2020-11-05]
    end
  end

  describe "day_of/1" do
    test "%Date{}" do
      date = ~D[2020-11-09]
      %DateTimeRange{from: from, to: to} = DateTimeRange.day_of(date)
      assert from == ~U[2020-11-09 00:00:00Z]
      assert to == ~U[2020-11-09 23:59:59Z]
    end

    test "%DateTime{}" do
      datetime = ~U[2020-11-09 23:59:59Z]
      %DateTimeRange{from: from, to: to} = DateTimeRange.day_of(datetime)
      assert from == ~U[2020-11-09 00:00:00Z]
      assert to == ~U[2020-11-09 23:59:59Z]
    end
  end

  describe "X-to_date" do
    setup do
      times =
        AppTime.new()
        |> AppTime.end_of_day()
        |> AppTime.start_of_year()
        |> AppTime.start_of_month()
        |> AppTime.times()

      ~M[times]
    end

    test "year to date", ~M[times] do
      %DateTimeRange{from: from, to: to} = DateTimeRange.year_to_date()
      assert Clock.equal(from, times.start_of_year)
      assert Clock.equal(to, times.end_of_day)
    end

    test "month to date", ~M[times] do
      %DateTimeRange{from: from, to: to} = DateTimeRange.month_to_date()
      assert Clock.equal(from, times.start_of_month)
      assert Clock.equal(to, times.end_of_day)
    end
  end

  describe "within" do
    setup do
      times =
        AppTime.new()
        |> AppTime.plus(:plus_ten, minutes: 10)
        |> AppTime.plus(:plus_five, minutes: 5)
        |> AppTime.plus(:now, minutes: 0)
        |> AppTime.plus(:minus_five, minutes: -5)
        |> AppTime.plus(:minus_ten, minutes: -10)
        |> AppTime.times()

      range = DateTimeRange.new(times.minus_five, times.plus_five)

      ~M[times, range]
    end

    test "before", ~M[times, range] do
      assert false == DateTimeRange.within?(range, times.minus_ten)
    end

    test "after", ~M[times, range] do
      assert false == DateTimeRange.within?(range, times.plus_ten)
    end

    test "within", ~M[times, range] do
      assert true == DateTimeRange.within?(range, times.now)
    end

    test "within equal to from", ~M[times, range] do
      assert true == DateTimeRange.within?(range, times.minus_five)
    end

    test "within equal to to", ~M[times, range] do
      assert true == DateTimeRange.within?(range, times.plus_five)
    end
  end

  describe "DateTimeRange.new()" do
    test "new, spread out times" do
      from =
        DateTime.utc_now()
        |> Timex.beginning_of_day()

      to =
        DateTime.utc_now()
        |> Timex.end_of_day()

      range = DateTimeRange.new(from, to)
      assert range.from == from
      assert range.to == to
    end

    test "new, same exact times, aka instant" do
      from_and_to =
        DateTime.utc_now()
        |> Timex.beginning_of_day()

      range = DateTimeRange.new(from_and_to, from_and_to)
      assert range.from == from_and_to
      assert range.to == from_and_to
    end

    test "new, invalid times" do
      from =
        DateTime.utc_now()
        |> Timex.beginning_of_day()

      to =
        DateTime.utc_now()
        |> Timex.end_of_day()

      message = "invalid range, 'from' must preceed 'to'. from:#{inspect(to)} to:#{inspect(from)}"

      assert_raise RuntimeError, message, fn ->
        DateTimeRange.new(to, from)
      end
    end
  end

  describe "DateTimeRange.today()" do
    test "struct" do
      result = DateTimeRange.today()
      assert result.__struct__ == AppCount.Core.DateTimeRange
    end

    test "from" do
      from = DateTime.utc_now() |> Timex.beginning_of_day()

      result = DateTimeRange.today()
      assert result.from == from
    end

    test "to" do
      to = DateTime.utc_now() |> Timex.end_of_day()

      result = DateTimeRange.today()
      assert result.to == to
    end

    test "to_list/1" do
      from = DateTime.utc_now() |> Timex.beginning_of_day()
      to = DateTime.utc_now() |> Timex.end_of_day()
      range = DateTimeRange.today()

      # When
      list = DateTimeRange.to_list(range)
      assert list == [from, to]
    end
  end

  describe "DateTimeRange.yesterday()" do
    test "from" do
      from =
        DateTime.utc_now()
        |> Timex.beginning_of_day()
        |> Timex.shift(hours: -24)

      result = DateTimeRange.yesterday()
      assert result.from == from
    end

    test "to" do
      to =
        DateTime.utc_now()
        |> Timex.end_of_day()
        |> Timex.shift(hours: -24)

      result = DateTimeRange.yesterday()
      assert result.to == to
    end
  end

  describe "DateTimeRange.last30days()" do
    test "from" do
      from =
        DateTime.utc_now()
        |> Timex.beginning_of_day()
        |> Timex.shift(days: -30)

      result = DateTimeRange.last30days()
      assert result.from == from
    end

    test "to" do
      to =
        DateTime.utc_now()
        |> Timex.end_of_day()

      result = DateTimeRange.last30days()
      assert result.to == to
    end
  end
end
