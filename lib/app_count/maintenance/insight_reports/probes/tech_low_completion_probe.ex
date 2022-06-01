defmodule AppCount.Maintenance.InsightReports.TechLowCompletionProbe do
  alias AppCount.Maintenance.Assignment
  use AppCount.Maintenance.InsightReports.ProbeBehaviour

  # When report is sent on anyday except Friday use this text:
  # "Based on the number of techs, we completed fewer work orders than expected today. Let's make that up tomorrow."

  # When report is sent on Friday use this text:
  # "Based on the number of techs, we completed fewer work orders than expected today. Let's make that up on Monday."

  # ----------------------------------
  @max_open_count 5
  @min_completed_per_tech 3

  # ----------------------------------

  @impl ProbeBehaviour
  def mood, do: :negative

  @impl ProbeBehaviour
  def insight_item(%ProbeContext{input: %{assignments: assignments, techs: techs}} = context) do
    comments = call(assignments, techs)
    reading = reading(context)

    %InsightItem{
      comments: comments,
      reading: reading,
      meta: %{mood: mood(), reporter: __MODULE__}
    }
  end

  @impl ProbeBehaviour
  def reading(%ProbeContext{}) do
    # Currently not needed so returns Nothing
    %AppCount.Maintenance.Reading{}
  end

  def call(assignments, techs, today_at \\ DateTime.utc_now())
      when is_list(assignments) and is_list(techs) do
    if open_count(assignments) < @max_open_count or length(techs) == 0 do
      []
    else
      complete_count = completion_count(assignments)
      num_of_techs = length(techs)
      day_of_week = dow(today_at)

      completed_per_tech = complete_count / num_of_techs

      if completed_per_tech <= @min_completed_per_tech do
        [
          message(day_of_week)
        ]
      else
        []
      end
    end
  end

  def message("Fri") do
    "Based on the number of techs, we completed fewer work orders than expected today. Let's make that up on Monday."
  end

  def message(_not_friday) do
    "Based on the number of techs, we completed fewer work orders than expected today. Let's make that up tomorrow."
  end

  def dow(datetime) do
    datetime
    |> DateTime.to_date()
    |> Timex.weekday()
    |> Timex.day_shortname()
  end

  def completion_count(assignments) when is_list(assignments) do
    assignments
    |> Enum.count(fn %Assignment{} = assignment ->
      Assignment.completed?(assignment)
    end)
  end

  def open_count(assignments) when is_list(assignments) do
    assignments
    |> Enum.count(fn %Assignment{} = assignment ->
      !Assignment.completed?(assignment)
    end)
  end
end
