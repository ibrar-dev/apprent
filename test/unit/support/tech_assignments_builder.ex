defmodule AppCount.Support.TechAssignmentsBuilder do
  @moduledoc """
  TechAssignmentsBuilder lets you setup the in-memory structs for testing reports
  """
  alias AppCount.Maintenance.Tech
  alias AppCount.Maintenance.Assignment
  alias AppCount.Support.AppTime

  defp completed_at do
    times =
      AppTime.new()
      |> AppTime.plus_to_naive(:yesterday, days: -1)
      |> AppTime.times()

    times.yesterday
  end

  defp assignment(completed_at, status \\ "in_progress", rating \\ nil) do
    # status: withdrawn, in_progress,  callback,  on_hold, pending
    %Assignment{
      status: status,
      completed_at: completed_at,
      rating: rating
    }
  end

  def add_assignment(tech, set_up_type, params \\ %{})

  def add_assignment(%Tech{assignments: assignments} = tech, :avg_completion_time, %{
        inserted_at: inserted_at,
        completed_at: completed_at
      }) do
    assignment =
      assignment(completed_at, "in_progress")
      |> Map.put(:inserted_at, inserted_at)

    %{tech | assignments: [assignment | assignments]}
  end

  def add_assignment(%Tech{assignments: assignments} = tech, :completion_count, _params) do
    assignment = assignment(completed_at())

    %{tech | assignments: [assignment | assignments]}
  end

  def add_assignment(%Tech{assignments: assignments} = tech, :rating, %{rating: rating}) do
    assignment = assignment(completed_at(), "in_progress", rating)

    %{tech | assignments: [assignment | assignments]}
  end

  def add_assignment(%Tech{assignments: assignments} = tech, :callback, _params) do
    assignment = assignment(completed_at(), "callback")

    %{tech | assignments: [assignment | assignments]}
  end

  def add_assignment(%Tech{assignments: assignments} = tech, :incomplete, _params) do
    assignment = assignment(nil)

    %{tech | assignments: [assignment | assignments]}
  end
end
