defmodule AppCount.Maintenance.InsightReports.WorkOrderRatingProbe do
  use AppCount.Maintenance.InsightReports.ProbeBehaviour

  @moduledoc """
  Given a property, a start_time, and an end_time, find the average of all
  submitted ratings for jobs completed within that timespan as of  `end_time`

  Value returned is between 0.0 and 5.0; If not ratings, value returned is `nil`
  """

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
  def reading(%ProbeContext{input: %{average_maintenance_rating: average_maintenance_rating}}) do
    (average_maintenance_rating || 0)
    |> Reading.work_order_rating()
  end
end
