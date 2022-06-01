defmodule AppCount.Maintenance.InsightReports.TechLowCompletionProbeTest do
  use AppCount.ProbeCase
  alias AppCount.Maintenance.Assignment
  alias AppCount.Maintenance.Tech
  alias AppCount.Maintenance.InsightReports.TechLowCompletionProbe

  def build_assignments(count, tech_name, completed_at) do
    1..count
    |> Enum.reduce([], fn _num, acc ->
      assignment = %Assignment{tech: %Tech{name: tech_name}, completed_at: completed_at}
      [assignment | acc]
    end)
  end

  test "insight_item", ~M[  today_range, property] do
    daily_context = ProbeContext.new([], [], property, today_range)

    # When
    insight_item = TechLowCompletionProbe.insight_item(daily_context)

    assert insight_item.comments == []
  end

  describe "has time of now" do
    setup do
      monday_noon = monday_noon()

      friday_noon = friday_noon()

      techs = [%Tech{name: "Ringo"}, %Tech{name: "John"}]
      ~M[monday_noon, friday_noon, techs]
    end

    test "call/3 with 0 techs" do
      assignment_list = build_assignments(7, "Ringo", nil)

      # When
      result = TechLowCompletionProbe.call(assignment_list, [], DateTime.utc_now())

      # Then
      assert result == []
    end

    test "tech has 3+ completed assignments, property has total of 4 OPEN",
         ~M[monday_noon, techs] do
      assignments =
        build_assignments(3, "Ringo", monday_noon) ++
          build_assignments(4, "John", nil)

      # When
      messages = TechLowCompletionProbe.call(assignments, techs)
      # Then
      assert messages == []
    end

    test "tech has fewer tha 3 completed assignments, but property has fewer than 5",
         ~M[monday_noon, techs] do
      assignments = build_assignments(2, "Ringo", monday_noon)
      # When
      messages = TechLowCompletionProbe.call(assignments, techs)
      # Then
      assert messages == []
    end

    test "tech has fewer tha 3 completed assignments, monday_noon",
         ~M[monday_noon, techs] do
      assignments =
        build_assignments(4, "Ringo", monday_noon) ++
          build_assignments(6, "Paul", nil)

      # When
      messages = TechLowCompletionProbe.call(assignments, techs, monday_noon)
      # Then
      assert messages == [
               "Based on the number of techs, we completed fewer work orders than expected today. Let's make that up tomorrow."
             ]
    end

    test "tech has fewer tha 3 completed assignments, friday_noon",
         ~M[friday_noon, techs] do
      assignments =
        build_assignments(4, "Ringo", friday_noon) ++
          build_assignments(6, "Paul", nil)

      # When
      messages = TechLowCompletionProbe.call(assignments, techs, friday_noon)
      # Then
      assert messages == [
               "Based on the number of techs, we completed fewer work orders than expected today. Let's make that up on Monday."
             ]
    end
  end
end
