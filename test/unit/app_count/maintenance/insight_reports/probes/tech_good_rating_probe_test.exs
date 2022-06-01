defmodule AppCount.Maintenance.InsightReports.TechGoodRatingProbeTest do
  use AppCount.ProbeCase
  alias AppCount.Maintenance.InsightReports.TechGoodRatingProbe
  alias AppCount.Maintenance.Assignment
  alias AppCount.Maintenance.Tech

  setup do
    assignments = %{
      one: %Assignment{rating: 1, tech: %Tech{name: "Tech-one"}},
      two: %Assignment{rating: 2, tech: %Tech{name: "Tech-two"}},
      three: %Assignment{rating: 3, tech: %Tech{name: "Tech-three"}},
      four: %Assignment{rating: 4, tech: %Tech{name: "Tech-four"}},
      five: %Assignment{rating: 5, tech: %Tech{name: "Tech-five"}}
    }

    ~M[assignments]
  end

  test "insight_item", ~M[  today_range, property] do
    daily_context = ProbeContext.new([], [], property, today_range)

    # When
    insight_item = TechGoodRatingProbe.insight_item(daily_context)

    assert insight_item.comments == []
  end

  describe "good_assignments " do
    test "assignments with bad rating", ~M[assignments] do
      not_good_ratings = [assignments.one, assignments.two, assignments.three]
      # When
      result = TechGoodRatingProbe.good_assignments(not_good_ratings)
      assert result == []
    end

    test "assignments with good rating", ~M[assignments] do
      good_ratings = [assignments.four, assignments.five]
      # When
      result = TechGoodRatingProbe.good_assignments(good_ratings)
      assert result == good_ratings
    end
  end

  describe "call " do
    test "no messages" do
      # When
      result = TechGoodRatingProbe.call([])
      assert result == []
    end

    test "all messages", ~M[assignments] do
      all_assignments = Map.values(assignments)
      _good_ratings = [assignments.five, assignments.four]
      # When
      result = TechGoodRatingProbe.call(all_assignments)

      assert result == [
               "Congratulations! Tech-five & Tech-four received 2 positive work order ratings today!"
             ]
    end

    test "message for Four", ~M[assignments] do
      assignments = [assignments.four]
      # When
      result = TechGoodRatingProbe.call(assignments)

      assert result == ["Congratulations! Tech-four received 1 positive work order rating today!"]
    end
  end
end
