defmodule AppCount.Maintenance.InsightReports.UnitVacantNotReadyProbe do
  @moduledoc """
  Given property and end_interval, find the number of NOT ready units as represented on Make Ready board

  Returns some integer >= 0 representing the count
  """

  use AppCount.Maintenance.InsightReports.ProbeBehaviour

  @impl ProbeBehaviour
  def mood, do: :neutral

  @impl ProbeBehaviour
  def insight_item(%ProbeContext{input: %{property: property, unit_tallies: unit_tallies}}) do
    count = call(unit_tallies)
    reading = reading(count, property)
    comments = []

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

  def reading(value, property) do
    Reading.new(
      :unit_vacant_not_ready,
      {value, :count},
      title: "Vacant Not Ready Units",
      display: "number",
      link_path: "make_ready?selected_properties=#{property.id}"
    )
  end

  def call(unit_tallies) do
    unit_tallies.not_ready
  end
end
