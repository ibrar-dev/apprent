defmodule AppCount.Maintenance.InsightReports.TechGoodRatingProbe do
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
    |> good_assignments()
    |> messages()
  end

  def messages([]) do
    []
  end

  def messages(good_assignments) when is_list(good_assignments) do
    count = Enum.count(good_assignments)
    rating_string = pluralize("rating", count)

    tech_names =
      good_assignments
      |> Enum.map(fn %Assignment{tech: %{name: name}} -> name end)
      |> Enum.uniq()
      |> Enum.sort()

    names = Enum.join(tech_names, " & ")

    [
      "Congratulations! #{names} received #{count} positive work order #{rating_string} today!"
    ]
  end

  def good_assignments(assignments) when is_list(assignments) do
    assignments
    |> Enum.filter(fn
      %Assignment{rating: 4} -> true
      %Assignment{rating: 5} -> true
      %Assignment{} -> false
    end)
  end

  defp pluralize("rating", 1) do
    "rating"
  end

  defp pluralize("rating", num) when num > 1 do
    "ratings"
  end
end
