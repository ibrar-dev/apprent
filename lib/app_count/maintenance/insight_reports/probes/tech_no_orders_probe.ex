defmodule AppCount.Maintenance.InsightReports.TechNoOrdersProbe do
  alias AppCount.Maintenance.Assignment
  alias AppCount.Maintenance.Tech
  use AppCount.Maintenance.InsightReports.ProbeBehaviour

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

  def call(assignments, all_techs) when is_list(assignments) and is_list(all_techs) do
    assignments
    |> completed_assignments()
    |> missing_techs(all_techs)
    |> messages()
  end

  def missing_techs(completed_assignments, all_techs) do
    techs_with_completions =
      completed_assignments
      |> Enum.map(fn %Assignment{tech: %{name: name}} -> name end)
      |> Enum.uniq()
      |> Enum.sort()

    Enum.reduce(all_techs, [], fn %Tech{name: tech_name}, missing_tech_names ->
      if tech_name in techs_with_completions do
        missing_tech_names
      else
        # not found in completions, so it's missing
        [tech_name | missing_tech_names]
      end
    end)
  end

  def messages([]) do
    []
  end

  def messages(tech_names) do
    anded_names = combine_with_and(tech_names)

    count = Enum.count(tech_names)

    message =
      "If #{anded_names} #{verb_to_be(count)} at work today, please check into why they completed zero work orders"

    [message]
  end

  def verb_to_be(1) do
    "was"
  end

  def verb_to_be(_) do
    "were"
  end

  def completed_assignments(assignments) when is_list(assignments) do
    assignments
    |> Enum.filter(fn
      %Assignment{completed_at: completed_at} when not is_nil(completed_at) -> true
      %Assignment{} -> false
    end)
  end

  def combine_with_and(list) when is_list(list) do
    comma_space = ", "
    space_comma = " ,"
    ampersand = " & "

    Enum.join(list, comma_space)
    |> String.reverse()
    |> String.replace(space_comma, ampersand, global: false)
    |> String.reverse()
  end
end
