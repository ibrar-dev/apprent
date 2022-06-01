defmodule AppCount.Maintenance.InsightReports.UnitVacantReadyProbe do
  @moduledoc """
  Given property and end_interval, find the number of vacant ready units

  Returns some integer >= 0 representing the count.
  """
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
    count = call(unit_tallies)

    Reading.new(
      :unit_vacant_ready,
      {count, :count},
      title: "Vacant Ready Units",
      display: "number",
      link_path: "make_ready?selected_properties="
    )
  end

  def call(unit_tallies) do
    count_vacant_ready(unit_tallies)
  end

  def count_vacant_ready(tallies) do
    tallies.ready
  end
end
