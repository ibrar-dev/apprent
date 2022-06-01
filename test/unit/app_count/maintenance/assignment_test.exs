defmodule AppCount.Maintenance.AssignmentTest do
  use AppCount.Case
  alias AppCount.Maintenance.Assignment

  describe "completion_hours" do
    setup do
      times =
        AppTime.new()
        |> AppTime.plus_to_naive(:now, hours: 0)
        |> AppTime.plus_to_naive(:one_hour_ago, hours: -1)
        |> AppTime.times()

      ~M[times]
    end

    test "incomplete completed_at", ~M[times] do
      assignment = %Assignment{inserted_at: times.now, completed_at: nil}
      # When
      result = Assignment.completion_hours(assignment)

      assert result == :incomplete
    end

    test "incomplete inserted_at", ~M[times] do
      assignment = %Assignment{completed_at: times.now, inserted_at: nil}
      # When
      result = Assignment.completion_hours(assignment)

      assert result == :incomplete
    end

    test "complete one hour", ~M[times] do
      assignment = %Assignment{inserted_at: times.one_hour_ago, completed_at: times.now}
      # When
      result = Assignment.completion_hours(assignment)

      assert result == 1
    end
  end
end
