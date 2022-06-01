defmodule AppCount.Maintenance.InsightReports.TechBadRatingProbeTest do
  use AppCount.ProbeCase
  alias AppCount.Maintenance.InsightReports.TechBadRatingProbe

  def build_assigment_with(rating, tech_name, order_id, unit_name) do
    %Assignment{
      rating: rating,
      tech: %Tech{name: tech_name},
      order_id: order_id,
      order: %Order{unit: %Unit{number: unit_name}}
    }
  end

  setup do
    assignments = %{
      one: build_assigment_with(1, "Tech-one", 1, "unit-1"),
      two: build_assigment_with(2, "Tech-two", 2, "unit-2"),
      three: build_assigment_with(3, "Tech-three", 3, "unit-3"),
      four: build_assigment_with(4, "Tech-four", 4, "unit-4"),
      five: build_assigment_with(5, "Tech-five", 5, "unit-5")
    }

    ~M[assignments]
  end

  test "insight_item", ~M[  today_range, property] do
    daily_context = ProbeContext.new([], [], property, today_range)

    # When
    insight_item = TechBadRatingProbe.insight_item(daily_context)

    assert insight_item.comments == []
  end

  describe "bad_assignments " do
    test "assignments with good rating", ~M[assignments] do
      not_good_ratings = [assignments.three, assignments.four, assignments.five]
      # When
      result = TechBadRatingProbe.bad_assignments(not_good_ratings)
      assert result == []
    end

    test "assignments with bad rating", ~M[assignments] do
      bad_ratings = [assignments.one, assignments.two]
      # When
      result = TechBadRatingProbe.bad_assignments(bad_ratings)
      assert result == bad_ratings
    end
  end

  describe "call " do
    test "no messages" do
      # When
      result = TechBadRatingProbe.call([])
      assert result == []
    end

    test "all messages", ~M[assignments] do
      all_assignments = Map.values(assignments)
      # When
      result = TechBadRatingProbe.call(all_assignments)

      assert result == [
               "Please follow up with resident in unit unit-1. Tech-one received a poor rating after completing <a href=\"http://residents.localhost:4001/order/1\">this work order</a>",
               "Please follow up with resident in unit unit-2. Tech-two received a poor rating after completing <a href=\"http://residents.localhost:4001/order/2\">this work order</a>"
             ]
    end

    test "message for One", ~M[assignments] do
      assignments = [assignments.one]
      # When
      result = TechBadRatingProbe.call(assignments)

      assert result == [
               "Please follow up with resident in unit unit-1. Tech-one received a poor rating after completing <a href=\"http://residents.localhost:4001/order/1\">this work order</a>"
             ]
    end
  end
end
