defmodule AppCount.Maintenance.InsightReports.TechBadRatingProbe do
  alias AppCount.Maintenance.Assignment
  alias AppCount.Maintenance.Order
  use AppCount.Maintenance.InsightReports.ProbeBehaviour

  @impl ProbeBehaviour
  def mood, do: :negative

  @impl ProbeBehaviour
  def insight_item(%ProbeContext{input: %{assignments: assignments}} = context) do
    messages = call(assignments)

    reading = reading(context)

    %InsightItem{
      comments: messages,
      reading: reading,
      meta: %{mood: mood(), reporter: __MODULE__}
    }
  end

  def call(assignments) when is_list(assignments) do
    bad_assignments = bad_assignments(assignments)

    messages(bad_assignments)
  end

  @impl ProbeBehaviour
  def reading(%ProbeContext{}) do
    # Currently not needed so returns Nothing
    %AppCount.Maintenance.Reading{}
  end

  def messages([]) do
    []
  end

  def messages(bad_assignments) do
    bad_assignment_tuples =
      bad_assignments
      |> Enum.map(fn %Assignment{
                       tech: %{name: name},
                       order_id: order_id,
                       order: %{unit: %{number: unit_number}}
                     } ->
        {unit_number, name, order_id}
      end)
      |> Enum.sort()

    bad_assignment_tuples
    |> Enum.map(fn {unit_num, tech_name, order_id} ->
      ~s[Please follow up with resident in unit #{unit_num}. #{tech_name} received a poor rating after completing <a href="#{
        Order.url(order_id)
      }">this work order</a>]
    end)
  end

  def bad_assignments(assignments) when is_list(assignments) do
    assignments
    |> Enum.filter(fn
      %Assignment{rating: 1} -> true
      %Assignment{rating: 2} -> true
      %Assignment{} -> false
    end)
  end
end
