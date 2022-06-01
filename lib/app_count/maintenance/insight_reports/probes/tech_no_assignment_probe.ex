defmodule AppCount.Maintenance.InsightReports.TechNoAssignmentProbe do
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

  def call(assignments, techs)
      when is_list(assignments) and is_list(techs) and length(techs) > 0 do
    all_tech_names =
      techs
      |> Enum.map(fn %Tech{name: name} -> name end)
      |> Enum.sort()

    assignments
    |> assigned_tech_names()
    |> missing_techs(all_tech_names)
    |> messages()
  end

  def call(_assignments, _techs) do
    []
  end

  def assigned_tech_names(assignments) when is_list(assignments) do
    assignments
    |> Enum.map(fn %Assignment{tech: %Tech{name: name}} -> name end)
    |> Enum.uniq()
    |> Enum.sort()
  end

  def missing_techs(assigned_tech_names, all_tech_names) do
    all_tech_names
    |> Enum.reject(fn name -> Enum.member?(assigned_tech_names, name) end)
  end

  def messages([]) do
    []
  end

  def messages(missing_tech_names) do
    anded_names = combine_with_and(missing_tech_names)

    count = Enum.count(missing_tech_names)

    verb = verb_to_be(count)

    message =
      "#{anded_names} #{verb} have any assigned work orders. Please make sure that all techs have work orders assigned."

    [message]
  end

  def verb_to_be(1) do
    "does not"
  end

  def verb_to_be(_) do
    "do not"
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
