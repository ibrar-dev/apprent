defmodule AppCount.Maintenance.InsightReports.DurationFormatterTest do
  # TODO: rename to AppCount.Core.DurationTest
  alias AppCount.Maintenance.InsightReports.Duration
  use AppCount.Case, async: true

  # Clickup https://app.clickup.com/t/dcmtwe
  #   We get durations in seconds. What we should see:
  # + 5 weeks, 3 days ("5 weeks" flat if 0 days)
  # + 5 months, 17 days ("5 months" flat if 0 days)

  @minute 60
  @hour 60 * @minute
  @day 24 * @hour
  @week 7 * @day
  @month 30 * @day

  describe "convert measurement without struct" do
    test "to_days" do
      assert Duration.to_days({@day, :seconds}) == {1, :days}
    end

    test "to_days rounded away" do
      days_plus_a_bit = @day + 20
      assert Duration.to_days({days_plus_a_bit, :seconds}) == {1.0, :days}
    end

    test "to_days rounded to 2 places" do
      days_plus_a_bit = @day + 2 * @hour
      assert Duration.to_days({days_plus_a_bit, :seconds}) == {1.08, :days}
    end

    test "to_seconds" do
      expected_seconds = 3 * @day
      assert Duration.to_seconds({3, :days}) == {expected_seconds, :seconds}
    end
  end

  describe "new Duration" do
    test "to_days" do
      duration = Duration.new({@day, :seconds})
      assert Duration.to_days(duration) == {1, :days}
    end

    test "to_seconds" do
      duration = Duration.new({2, :days})
      assert Duration.to_seconds(duration) == {2 * @day, :seconds}
    end

    test "display(%Duration{})" do
      duration = Duration.new({2, :days})
      assert Duration.display(duration) == "2 days"
    end
  end

  describe "displays/2" do
    test "12 minutes" do
      duration = 12 * @minute
      result = Duration.display({duration, :seconds})

      assert result == "12 minutes"
    end

    test "12 minutes as float" do
      duration = 12.0 * @minute
      result = Duration.display({duration, :seconds})

      assert result == "12 minutes"
    end

    test "1 minute" do
      duration = 1 * @minute
      result = Duration.display({duration, :seconds})

      assert result == "1 minute"
    end

    test "1 hour" do
      duration = 1 * @hour
      result = Duration.display({duration, :seconds})

      assert result == "1 hour"
    end

    test "1 hour as float" do
      duration = 1.0 * @hour
      result = Duration.display({duration, :seconds})

      assert result == "1 hour"
    end

    test "1 hour 1 minute" do
      duration = 1 * @hour + 1 * @minute
      result = Duration.display({duration, :seconds})

      assert result == "1 hour, 1 minute"
    end

    test " > 1 year" do
      duration = 366 * @day
      result = Duration.display({duration, :seconds})

      assert result == "> 1 year"
    end

    test "> 1 year as float" do
      duration = 367.0 * @day

      result = Duration.display({duration, :seconds})
      assert result == "> 1 year"
    end

    test "4 hours, 12 minutes" do
      duration = 4 * @hour + 12 * @minute
      result = Duration.display({duration, :seconds})

      assert result == "4 hours, 12 minutes"
    end

    test "4 hours, 0 minutes" do
      duration = 4 * @hour
      result = Duration.display({duration, :seconds})

      assert result == "4 hours"
    end

    test "4 hours, 0 minutes as float" do
      duration = 4.0 * @hour
      result = Duration.display({duration, :seconds})

      assert result == "4 hours"
    end

    test "3 days, 4 hours" do
      duration = 3 * @day + 4 * @hour
      result = Duration.display({duration, :seconds})

      assert result == "3 days, 4 hours"
    end

    test "3 days" do
      duration = 3 * @day
      result = Duration.display({duration, :seconds})

      assert result == "3 days"
    end

    test "3 weeks" do
      duration = 3 * @week
      result = Duration.display({duration, :seconds})

      assert result == "3 weeks"
    end

    test "3 weeks as float" do
      duration = 3.0 * @week
      result = Duration.display({duration, :seconds})

      assert result == "3 weeks"
    end

    test "5 weeks" do
      duration = 35 * @day
      result = Duration.display({duration, :seconds})

      assert result == "1 month"
    end

    test "less than 1 hour" do
      duration = 42 * 60

      result = Duration.display({duration, :seconds})

      assert result == "42 minutes"
    end

    test "less than 1 day" do
      duration = 12 * @hour
      result = Duration.display({duration, :seconds})

      assert result == "12 hours"
    end

    test "more than 1 day" do
      duration = 4 * @day + 12 * @hour
      result = Duration.display({duration, :seconds})

      assert result == "4 days, 12 hours"
    end

    test "with days, hours, and minutes" do
      duration = 4 * @day + 3 * @hour + 2 * @minute
      result = Duration.display({duration, :seconds})

      assert result == "4 days, 3 hours"
    end

    test "with months, weeks, days, hours, and minutes" do
      duration = 1 * @month + 2 * @week + 4 * @day + 3 * @hour + 2 * @minute
      result = Duration.display({duration, :seconds})

      assert result == "1 month, 2 weeks"
    end

    test "with a zeroed second value" do
      duration = 2 * @month + 0 * @week + 4 * @day + 2 * @hour + @minute
      result = Duration.display({duration, :seconds})

      assert result == "2 months"
    end

    test "with weird increments" do
      duration = 7 * @month + 4 * @hour
      result = Duration.display({duration, :seconds})

      assert result == "7 months"
    end

    test "more than 1 day as float" do
      duration = 4.5 * @day
      result = Duration.display({duration, :seconds})

      assert result == "4 days, 12 hours"
    end

    test "given nil" do
      duration = nil
      result = Duration.display({duration, :seconds})

      assert result == "N/A"
    end
  end
end
