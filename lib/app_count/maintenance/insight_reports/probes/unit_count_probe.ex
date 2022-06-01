defmodule AppCount.Maintenance.InsightReports.UnitCountProbe do
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
  def reading(%ProbeContext{input: %{unit_tallies: unit_tallies}}) do
    total = unit_tallies.ready + unit_tallies.not_ready
    Reading.unit_count(total)
  end
end
