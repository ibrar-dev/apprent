defmodule AppCount.Maintenance.InsightReports.WorkOrderCompletedProbe do
  use AppCount.Maintenance.InsightReports.ProbeBehaviour

  @moduledoc """
  Given property, start_time, and end_time, count work orders completed in that
  timeframe
  """

  @impl ProbeBehaviour
  def mood, do: :positive

  @impl ProbeBehaviour
  def insight_item(%ProbeContext{} = context) do
    comments = []
    reading = reading(context)

    %InsightItem{
      comments: comments,
      reading: reading,
      meta: %{mood: mood(), reporter: __MODULE__}
    }
  end

  @impl ProbeBehaviour
  def reading(%ProbeContext{
        input: %{completed_orders: completed_orders}
      }) do
    Reading.work_order_completed(completed_orders)
  end

  def call(completed_orders) do
    completed_orders
  end
end
