defmodule AppCount.Maintenance.InsightReports.TechNoAssignmentProbeTest do
  use AppCount.ProbeCase
  alias AppCount.Maintenance.InsightReports.TechNoAssignmentProbe

  setup do
    fab_four_techs = [
      %Tech{name: "George"},
      %Tech{name: "John"},
      %Tech{name: "Paul"},
      %Tech{name: "Ringo"}
    ]

    assignments = [
      %Assignment{tech: %Tech{name: "Paul"}},
      %Assignment{tech: %Tech{name: "John"}}
    ]

    techs_with_no_assigns = [
      %Tech{name: "Richard D. James"},
      %Tech{name: "Efrim Menuck"},
      %Tech{name: "Blaise Bailey Finnegan III"},
      %Tech{name: "Murray Ostril"}
    ]

    ~M[assignments, fab_four_techs, techs_with_no_assigns]
  end

  test "insight_item", ~M[  today_range, property] do
    daily_context = ProbeContext.new([], [], property, today_range)

    # When
    insight_item = TechNoAssignmentProbe.insight_item(daily_context)

    assert insight_item.comments == []
  end

  describe "has assignments and techs" do
    test "Everyone has assignments", ~M[assignments] do
      techs_with_assignments = [
        %Tech{name: "John"},
        %Tech{name: "Paul"}
      ]

      # When
      messages = TechNoAssignmentProbe.call(assignments, techs_with_assignments)

      assert messages == []
    end

    test "Ringo had no assignments", ~M[assignments, fab_four_techs] do
      [_drop_grorge | three_techs] = fab_four_techs
      # When
      messages = TechNoAssignmentProbe.call(assignments, three_techs)

      assert messages == [
               "Ringo does not have any assigned work orders. Please make sure that all techs have work orders assigned."
             ]
    end

    test "Ringo and George have no assignments", ~M[assignments, fab_four_techs] do
      # When
      messages = TechNoAssignmentProbe.call(assignments, fab_four_techs)

      assert messages == [
               "George & Ringo do not have any assigned work orders. Please make sure that all techs have work orders assigned."
             ]
    end

    test "no techs have no assignments" do
      # When
      messages = TechNoAssignmentProbe.call([], [])

      assert messages == []
    end
  end

  describe "No assignments" do
    test "with buncha lazy techs", ~M[assignments,  techs_with_no_assigns] do
      messages = TechNoAssignmentProbe.call(assignments, techs_with_no_assigns)

      assert messages == [
               "Blaise Bailey Finnegan III, Efrim Menuck, Murray Ostril & Richard D. James do not have any assigned work orders. Please make sure that all techs have work orders assigned."
             ]
    end

    test "no assignments for techs", ~M[  techs_with_no_assigns] do
      messages = TechNoAssignmentProbe.call([], techs_with_no_assigns)

      assert messages == [
               "Blaise Bailey Finnegan III, Efrim Menuck, Murray Ostril & Richard D. James do not have any assigned work orders. Please make sure that all techs have work orders assigned."
             ]
    end

    test "no techs for assignments ", ~M[  assignments] do
      messages = TechNoAssignmentProbe.call(assignments, [])

      assert messages == []
    end
  end
end
