defmodule AppCount.Maintenance.InsightReports.PerformanceScoreTest do
  use AppCount.ProbeCase
  alias AppCount.Maintenance.InsightReports.PerformanceScore
  alias AppCount.Maintenance.InsightReports.Duration
  alias AppCount.Maintenance.Reading

  describe "total score" do
    test "great score " do
      score = PerformanceScore.best_score()
      result = PerformanceScore.scale(score)
      assert result == 100.0
    end

    test "middle score" do
      score = %PerformanceScore{
        property_name: "Middle Score",
        work_order_saturation: 12.5,
        callbacks: 7.5,
        violations: 0,
        ratings: 2.5,
        work_order_turnaround: 7.5,
        make_ready_turnaround: 7.5,
        make_ready_percent: 7.5,
        make_ready_utilization: 7.5
      }

      result = PerformanceScore.scale(score)

      assert result == 50.0
    end

    test "rounded score" do
      score = %PerformanceScore{
        property_name: "Rounded Score",
        work_order_saturation: 0,
        callbacks: 7.5,
        violations: 0,
        ratings: 0,
        work_order_turnaround: 7.5,
        make_ready_turnaround: 7.5,
        make_ready_percent: 7.5,
        make_ready_utilization: 7.5
      }

      result = PerformanceScore.scale(score)
      # non-rounded: 35.714285714285715
      assert result == 35.71
    end

    test "poor score " do
      score = PerformanceScore.worst_score()
      result = PerformanceScore.scale(score)

      assert result == 0.0
    end
  end

  describe "gather readings" do
    setup do
      builder =
        PropBuilder.new(:create)
        |> PropBuilder.add_property()
        |> PropBuilder.add_unit()
        |> PropBuilder.add_unit_category()
        |> PropBuilder.add_tech()
        |> PropBuilder.add_work_order_on_unit()

      property =
        builder
        |> PropBuilder.get_requirement(:property)

      date_range_today = DateTimeRange.today()

      ~M[builder, property, date_range_today]
    end

    test "reading names", ~M[property, date_range_today] do
      # When
      readings =
        ProbeContext.load(property, date_range_today)
        |> PerformanceScore.readings()

      names = readings |> Enum.map(fn reading -> reading.name end)

      assert names == [
               :property_name,
               :unit_count,
               :work_order_callbacks,
               :work_order_violations,
               :work_order_rating,
               :work_order_saturation,
               :work_order_turnaround,
               :make_ready_turnaround,
               :make_ready_percent,
               :make_ready_utilization
             ]
    end
  end

  test "Great score from Readings" do
    expected = %PerformanceScore{
      property_name: "Great Property",
      work_order_saturation: 25.0,
      callbacks: 7.5,
      violations: 7.5,
      ratings: 5,
      work_order_turnaround: 15,
      make_ready_turnaround: 15,
      make_ready_percent: 15.0,
      make_ready_utilization: 15.0
    }

    {day_in_seconds, :seconds} =
      {1, :days}
      |> Duration.to_seconds()

    readings = [
      Reading.work_order_callbacks(0),
      Reading.make_ready_percent(99.9),
      Reading.make_ready_turnaround(day_in_seconds),
      Reading.make_ready_utilization(100.00),
      Reading.work_order_turnaround(1),
      Reading.property_name("Great Property"),
      Reading.work_order_rating(5),
      Reading.work_order_saturation(0),
      Reading.unit_count(1000),
      Reading.work_order_violations(0)
    ]

    # When
    score = PerformanceScore.from_readings(readings)

    # Then
    assert expected.property_name == score.property_name
    assert expected.work_order_saturation == score.work_order_saturation
    assert expected.callbacks == score.callbacks
    assert expected.violations == score.violations
    assert expected.ratings == score.ratings
    assert expected.work_order_turnaround == score.work_order_turnaround
    assert expected.make_ready_turnaround == score.make_ready_turnaround
    assert expected.make_ready_percent == score.make_ready_percent
    assert expected.make_ready_utilization == score.make_ready_utilization
  end

  test "POOR score from Readings" do
    expected = %PerformanceScore{
      property_name: "Poor Property",
      work_order_saturation: 0.0,
      callbacks: 0,
      violations: 0,
      ratings: 0,
      work_order_turnaround: 0,
      make_ready_turnaround: 0,
      make_ready_percent: 0.0,
      make_ready_utilization: 0.0
    }

    {hundred_days, :seconds} =
      {100, :days}
      |> Duration.to_seconds()

    readings = [
      Reading.work_order_callbacks(1),
      Reading.make_ready_percent(40),
      Reading.make_ready_turnaround(0),
      Reading.make_ready_utilization(0),
      Reading.work_order_turnaround(hundred_days),
      Reading.property_name("Poor Property"),
      Reading.work_order_rating(0),
      Reading.work_order_saturation(32.8),
      Reading.unit_count(305),
      Reading.work_order_violations(1)
    ]

    # When
    score = PerformanceScore.from_readings(readings)
    # Then
    assert expected.property_name == score.property_name
    assert expected.work_order_saturation == score.work_order_saturation
    assert expected.callbacks == score.callbacks
    assert expected.violations == score.violations
    assert expected.ratings == score.ratings
    assert expected.work_order_turnaround == score.work_order_turnaround
    assert expected.make_ready_turnaround == score.make_ready_turnaround
    assert expected.make_ready_percent == score.make_ready_percent
    assert expected.make_ready_utilization == score.make_ready_utilization
  end
end
