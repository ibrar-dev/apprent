defmodule AppCount.Maintenance.InsightReports.TechNoOrdersProbeTest do
  use AppCount.ProbeCase
  alias AppCount.Maintenance.InsightReports.TechNoOrdersProbe

  setup do
    now = DateTime.utc_now()

    techs = [
      %Tech{name: "George"},
      %Tech{name: "Paul"},
      %Tech{name: "Ringo"}
    ]

    assignments = %{
      paul_one: %Assignment{tech: %Tech{name: "Paul"}, completed_at: now},
      paul_two: %Assignment{tech: %Tech{name: "Paul"}, completed_at: now},
      george_complete: %Assignment{tech: %Tech{name: "George"}, completed_at: now},
      george_incomplete: %Assignment{tech: %Tech{name: "George"}, completed_at: nil}
    }

    ~M[assignments, techs]
  end

  test "insight_item", ~M[  today_range, property] do
    daily_context = ProbeContext.new([], [], property, today_range)

    # When
    insight_item = TechNoOrdersProbe.insight_item(daily_context)

    assert insight_item.comments == []
  end

  describe "has assignments and techs" do
    test "Ringo had no completed assignments", ~M[assignments, techs] do
      assignments = [assignments.paul_one, assignments.paul_two, assignments.george_complete]
      # When
      messages = TechNoOrdersProbe.call(assignments, techs)

      assert messages == [
               "If Ringo was at work today, please check into why they completed zero work orders"
             ]
    end

    test "George had no COMPLETED assignments", ~M[assignments, techs] do
      assignments = [assignments.paul_one, assignments.paul_two, assignments.george_incomplete]
      # When
      messages = TechNoOrdersProbe.call(assignments, techs)

      assert messages == [
               "If Ringo & George were at work today, please check into why they completed zero work orders"
             ]
    end

    test "no one had a COMPLETED assignments", ~M[techs] do
      assignments = []
      # When
      messages = TechNoOrdersProbe.call(assignments, techs)

      assert messages == [
               "If Ringo, Paul & George were at work today, please check into why they completed zero work orders"
             ]
    end
  end

  describe "combine_with_and/1 " do
    test "George" do
      expected_list = "George"

      result = TechNoOrdersProbe.combine_with_and(["George"])
      assert result == expected_list
    end

    test "George & Ringo" do
      expected_list = "George & Ringo"

      result = TechNoOrdersProbe.combine_with_and(["George", "Ringo"])
      assert result == expected_list
    end

    test "George, Ringo & John" do
      expected_list = "George, Ringo & John"

      result = TechNoOrdersProbe.combine_with_and(["George", "Ringo", "John"])
      assert result == expected_list
    end
  end
end
