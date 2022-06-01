defmodule AppCount.Maintenance.InsightReports.UnitVacantProbe do
  @moduledoc """
  Given property and end_interval, find the number of vacant units (regardless of ready status)

  Returns some integer >= 0 representing the count of vacant units on make-ready board
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
    Reading.unit_vacant(count)
  end

  def reading(value, property) do
    Reading.new(
      :unit_vacant,
      {value, :count},
      title: "Total Vacant Units",
      display: "number",
      link_path: "make_ready?selected_properties=#{property.id}"
    )
  end

  def call(unit_tallies) do
    count_vacant(unit_tallies)
  end

  def count_vacant(tallies) do
    tallies.ready + tallies.not_ready
  end
end
