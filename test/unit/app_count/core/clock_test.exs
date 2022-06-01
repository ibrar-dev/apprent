defmodule AppCount.Core.ClockTest do
  use ExUnit.Case, async: true
  alias AppCount.Core.Clock

  def monday_noon do
    ~U[2020-11-09 12:00:00Z]
  end

  def monday do
    ~D[2020-11-09]
  end

  describe "now" do
    test "Clock.now/0" do
      result = Clock.now()
      assert :eq == Date.compare(result, Date.utc_today())
    end

    test "plus 10 seconds" do
      expected_time = DateTime.utc_now() |> Timex.shift(seconds: 10) |> DateTime.truncate(:second)
      result = Clock.now({10, :seconds})
      assert :eq == DateTime.compare(result, expected_time)
    end

    test "plus 10 minutes" do
      expected_time = DateTime.utc_now() |> Timex.shift(minutes: 10) |> DateTime.truncate(:second)
      result = Clock.now({10, :minutes})
      assert :eq == DateTime.compare(result, expected_time)
    end

    test "plus 10 hours " do
      expected_time = DateTime.utc_now() |> Timex.shift(hours: 10) |> DateTime.truncate(:second)
      result = Clock.now({10, :hours})
      assert :eq == DateTime.compare(result, expected_time)
    end

    test "plus 10 days" do
      expected = DateTime.utc_now() |> Timex.shift(days: 10) |> DateTime.truncate(:second)
      result = Clock.now({10, :days})
      assert result == expected
    end
  end

  describe "less than/2" do
    test "works for Date struct" do
      present = Date.utc_today()
      past = Date.utc_today() |> Timex.shift(days: -5)
      future = Date.utc_today() |> Timex.shift(days: 8)

      assert Clock.less_than(present, future)
      refute Clock.less_than(present, past)
    end

    test "works for DateTime struct" do
      present = DateTime.utc_now()
      past = DateTime.utc_now() |> Timex.shift(days: -5)
      future = DateTime.utc_now() |> Timex.shift(days: 8)

      assert Clock.less_than(present, future)
      refute Clock.less_than(present, past)
    end
  end

  describe "today" do
    test " Clock.today/0" do
      result = Clock.today()
      assert result == Date.utc_today()
    end

    test "plus 10 days" do
      expected = Date.utc_today() |> Date.add(10)
      result = Clock.today({10, :days})
      assert :eq == Date.compare(result, expected)
    end
  end

  describe "beginning_of_month" do
    test "one" do
      month_start = Clock.beginning_of_month()
      assert month_start.day == 1
    end
  end

  describe "date_from_iso8601!(string)" do
    test "normal" do
      string = "2018-07-03"
      expected = ~D[2018-07-03]

      # When
      actual = Clock.date_from_iso8601!(string)
      assert expected == actual
    end
  end

  describe "bod/1" do
    test "normal" do
      today = Clock.today()
      expected = DateTime.utc_now() |> Timex.beginning_of_day() |> DateTime.truncate(:second)

      # When
      actual = Clock.bod(today)
      assert expected == actual
    end

    test "tz_nyc" do
      today = monday()
      expected = "2020-11-09 00:00:00-05:00 EST America/New_York"

      # When
      actual = Clock.bod(today, Clock.tz_nyc())
      assert expected == DateTime.to_string(actual)
    end
  end

  describe "eod/1" do
    test "normal" do
      today = monday()
      expected = DateTime.new!(today, ~T[23:59:59], "Etc/UTC")
      # When
      actual = Clock.eod(today)
      assert expected == actual
    end

    test "tz_nyc" do
      today = monday()
      expected = "2020-11-09 23:59:59-05:00 EST America/New_York"

      # When
      actual = Clock.eod(today, Clock.tz_nyc())
      assert expected == DateTime.to_string(actual)
    end
  end

  describe "to_zone/2" do
    test "converts with datetime" do
      eod_today = monday() |> Clock.eod()
      expected = "2020-11-09 17:59:59-06:00 CST US/Central"

      # When
      actual = Clock.to_zone(eod_today, "US/Central")
      assert expected == DateTime.to_string(actual)
    end

    test "converts with naive datetime" do
      now = ~N[2021-02-21 00:00:00]

      expected = "2021-02-20 18:00:00-06:00 CST US/Central"
      actual = Clock.to_zone(now, "US/Central")
      assert expected == DateTime.to_string(actual)
    end
  end

  describe "to_nyc/1" do
    test "normal" do
      eod_today = monday() |> Clock.eod()
      expected = "2020-11-09 18:59:59-05:00 EST America/New_York"

      # When
      actual = Clock.to_nyc(eod_today)
      assert expected == DateTime.to_string(actual)
    end

    test "eod" do
      today = monday_noon()
      expected = "2020-11-09 07:00:00-05:00 EST America/New_York"

      # When
      actual = Clock.to_nyc(today)
      assert expected == DateTime.to_string(actual)
    end
  end

  describe "thirty_days" do
    test "one" do
      date = Clock.thirty_days()
      expected = Date.utc_today() |> Timex.shift(days: 30)
      assert :eq == Date.compare(date, expected)
    end
  end
end
