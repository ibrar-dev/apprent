defmodule AppCount.Maintenance.InsightReports.InsightReportFormatterTest do
  use AppCount.Case, async: true
  alias AppCount.Maintenance.InsightReports.InsightReportFormatter, as: Formatter

  describe "format/1 - number display" do
    test "handles nil value" do
      input = %{
        display: "number",
        value: nil,
        tag: "some tag",
        title: "some title"
      }

      assert Formatter.format(input) == "N/A"
    end

    test "handles value without tag" do
      input = %{
        display: "number",
        value: 24,
        title: "some title"
      }

      assert Formatter.format(input) == "24"
    end

    test "handles value with tag" do
      input = %{
        display: "number",
        value: 24,
        tag: "dogs",
        title: "some title"
      }

      assert Formatter.format(input) == "24 (dogs)"
    end
  end

  describe "format/1 - duration display" do
    test "handles nil value" do
      input = %{
        display: "duration",
        value: nil,
        tag: "jobs completed in the last 24 hours",
        title: "Average Completion Time"
      }

      assert Formatter.format(input) == "N/A"
    end

    test "handles duration in seconds > 1 day" do
      input = %{
        display: "duration",
        value: 100_000,
        title: "Average Completion Time"
      }

      assert Formatter.format(input) == "1 day, 3 hours"
    end

    test "handles duration in seconds < 1 day" do
      input = %{
        display: "duration",
        value: 18360,
        title: "Average Completion Time"
      }

      assert Formatter.format(input) == "5 hours, 6 minutes"
    end

    test "handles duration with tag" do
      input = %{
        display: "duration",
        value: 100_000,
        tag: "for jobs completed in the last 24 hours",
        title: "Average Completion Time"
      }

      assert Formatter.format(input) == "1 day, 3 hours (for jobs completed in the last 24 hours)"
    end
  end

  describe "format/1 - percentage display" do
    test "converts with integer value" do
      input = %{
        display: "percentage",
        value: 86,
        title: "Make Ready"
      }

      assert Formatter.format(input) == "86.0%"
    end

    test "converts with float value" do
      input = %{
        display: "percentage",
        value: 82.33333333,
        title: "Make Ready"
      }

      assert Formatter.format(input) == "82.3%"
    end

    test "converts with nil value" do
      input = %{
        display: "percentage",
        value: nil,
        title: "Make Ready"
      }

      assert Formatter.format(input) == "N/A"
    end

    test "handles 0" do
      input = %{
        display: "percentage",
        value: 0,
        title: "Make Ready"
      }

      assert Formatter.format(input) == "0.0%"
    end
  end

  describe "format/1 - rating display" do
    test "handles an average value of nil " do
      input = %{
        display: "rating",
        tag: "last 30 days",
        title: "Average Maintenance Rating",
        value: nil
      }

      assert Formatter.format(input) == "N/A"
    end

    test "handles a zero for average rating" do
      input = %{
        display: "rating",
        tag: "last 30 days",
        title: "Average Maintenance Rating",
        value: 0
      }

      assert Formatter.format(input) == "0.0/5 (last 30 days)"
    end

    test "handles an average value with no tag" do
      input = %{
        display: "rating",
        tag: nil,
        title: "Average Maintenance Rating",
        value: 3.917612
      }

      assert Formatter.format(input) == "3.9/5"
    end

    test "handles an average value with tag containing empty string" do
      input = %{
        display: "rating",
        tag: "",
        title: "Average Maintenance Rating",
        value: 3.5137761
      }

      assert Formatter.format(input) == "3.5/5"
    end

    test "handles an average value with tag containing empty string with spaces inside" do
      input = %{
        display: "rating",
        tag: "   ",
        title: "Average Maintenance Rating",
        value: 4.5137761
      }

      assert Formatter.format(input) == "4.5/5"
    end
  end
end
