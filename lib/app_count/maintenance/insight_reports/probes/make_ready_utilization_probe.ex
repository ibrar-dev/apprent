defmodule AppCount.Maintenance.InsightReports.MakeReadyUtilizationProbe do
  use AppCount.Maintenance.InsightReports.ProbeBehaviour
  alias AppCount.Maintenance.Utils.Cards

  @moduledoc """
  Given property and a date, find the make ready utilization percentage.

  The make ready utilization percentage is defined as:
  Number of vacant units on the make ready / number of total vacant units in the database

  Returns a percentage from 0-100%, otherwise returns nil if there are no vacant units in the database
  """
  @impl ProbeBehaviour
  def mood, do: :neutral

  @impl ProbeBehaviour
  def insight_item(%ProbeContext{} = context) do
    reading = reading(context)
    comments = comments(reading.value)

    %InsightItem{
      comments: comments,
      reading: reading,
      meta: %{mood: mood(), reporter: __MODULE__}
    }
  end

  @impl ProbeBehaviour
  def reading(%ProbeContext{input: %{property: property, unit_status: unit_status}}) do
    percentage = calculate_percentage(property, unit_status)
    Reading.make_ready_utilization(percentage)
  end

  def calculate_percentage(property, unit_status) do
    make_ready_vacant_count = make_ready_vacant_count(property)

    total_vacant_count = total_vacant_count(unit_status)

    if total_vacant_count == 0 do
      0.0
    else
      (make_ready_vacant_count / total_vacant_count * 100)
      |> Float.round(1)
    end
  end

  def comments(percentage) do
    cond do
      is_nil(percentage) ->
        []

      percentage >= 90.0 ->
        ["Great job utilizing the Make Ready board!"]

      percentage <= 75.0 && percentage > 0 ->
        ["The Make Ready is missing some vacant units. Please work to include them."]

      true ->
        []
    end
  end

  # returns the number of vacant units on the Make Ready board
  def make_ready_vacant_count(property) do
    ready_count = Cards.ready_units_count(property)

    not_ready_count = Cards.not_ready_units_count(property)

    ready_count + not_ready_count
  end

  # returns the number of vacant units in the repo
  def total_vacant_count(unit_status) do
    desired_statuses = [
      "Vacant Unrented Not Ready",
      "Vacant Unrented Ready",
      "Vacant Rented Ready",
      "Vacant Rented Not Ready",
      "Notice Unrented",
      "Notice Rented"
    ]

    unit_status
    |> Enum.filter(fn x -> x.status in desired_statuses end)
    |> length()
  end
end
