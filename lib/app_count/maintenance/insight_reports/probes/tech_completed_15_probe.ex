defmodule AppCount.Maintenance.InsightReports.TechCompleted15Probe do
  alias AppCount.Maintenance.Assignment
  use AppCount.Maintenance.InsightReports.ProbeBehaviour

  @impl ProbeBehaviour
  def mood, do: :positive

  @impl ProbeBehaviour
  def insight_item(%ProbeContext{input: %{assignments: assignments}} = context) do
    comments = call(assignments)
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

  def call(assignments) when is_list(assignments) do
    assignments
    |> completed_assignments()
    |> tech_name_count()
    |> messages()
  end

  def tech_name_count(completed_assignments) do
    completed_assignments
    |> Enum.group_by(fn %Assignment{tech: %{name: name}} -> name end)
    |> Enum.map(fn {tech_name, assignments} ->
      {tech_name, Enum.count(assignments)}
    end)
  end

  def messages([]) do
    []
  end

  def messages(tech_name_counts) when is_list(tech_name_counts) do
    tech_name_counts
    |> Enum.reduce([], fn
      {_tech_name, count}, messages when count < 15 -> messages
      {tech_name, count}, messages -> add_message({tech_name, count}, messages)
    end)
  end

  def add_message({tech_name, count}, messages) do
    message = "Special shout-out to #{tech_name} who completed #{count} work orders today!"
    [message | messages]
  end

  def completed_assignments(assignments) when is_list(assignments) do
    assignments
    |> Enum.filter(fn
      %Assignment{completed_at: completed_at} when not is_nil(completed_at) -> true
      %Assignment{} -> false
    end)
  end
end
