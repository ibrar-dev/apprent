defmodule AppCount.Maintenance.InsightReports.MakeReadyPercentageProbe do
  @moduledoc """
  Given property and end_interval, find the make-ready percentage.

  The make-ready percentage is defined as:

  Number of ready vacant units / number of vacant units

  Or, in human terms, the number of vacant units that are ready for move-in

  Returns:

  + nil if zero vacant units
  + Some percentage 0.0 - 100.0 if any vacant units
  """

  use AppCount.Maintenance.InsightReports.ProbeBehaviour

  @impl ProbeBehaviour
  def mood, do: :neutral

  @impl ProbeBehaviour
  def insight_item(%ProbeContext{input: %{unit_tallies: unit_tallies}} = context) do
    reading = reading(context)
    comments = comments(reading.value, unit_tallies.not_ready)

    %InsightItem{
      comments: comments,
      reading: reading,
      meta: %{mood: mood(), reporter: __MODULE__}
    }
  end

  @impl ProbeBehaviour
  def reading(%ProbeContext{input: %{unit_tallies: unit_tallies}}) do
    percentage = calculate_percentage(unit_tallies)
    Reading.make_ready_percent(percentage)
  end

  def comments(percentage, total_not_ready) do
    cond do
      percentage == 0 ->
        []

      percentage >= 80 ->
        ["Great job having #{percentage}% of your units ready!"]

      percentage < 70 && total_not_ready >= 5 ->
        ["Make-Readies need some work here. Please work to get it at least 80%"]

      true ->
        []
    end
  end

  def calculate_percentage(tallies) do
    total_vacant = tallies.ready + tallies.not_ready

    total_ready = tallies.ready

    if total_vacant == 0 do
      0
    else
      (total_ready / total_vacant * 100)
      |> Float.round(1)
    end
  end
end
