defmodule AppCount.Maintenance.InsightReports.PropertyNameProbe do
  use AppCount.Maintenance.InsightReports.ProbeBehaviour

  @impl ProbeBehaviour
  def mood, do: :neutral

  @impl ProbeBehaviour
  def insight_item(%ProbeContext{} = context) do
    reading = reading(context)
    comments = []

    %InsightItem{
      comments: comments,
      reading: reading,
      meta: %{mood: mood(), reporter: __MODULE__}
    }
  end

  @impl ProbeBehaviour
  def reading(%ProbeContext{input: %{property: %{name: name}}}) do
    Reading.property_name(name)
  end
end
