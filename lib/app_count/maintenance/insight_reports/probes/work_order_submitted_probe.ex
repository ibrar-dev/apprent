defmodule AppCount.Maintenance.InsightReports.WorkOrdersSubmittedProbe do
  use AppCount.Maintenance.InsightReports.ProbeBehaviour

  @moduledoc """
  Given a property, start_timestamp, and cutoff_timestamp, find all work orders
  submitted within the time interval (inclusive) and return the count of those
  orders
  """

  @impl ProbeBehaviour
  def mood, do: :neutral

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
  def reading(%ProbeContext{input: %{submitted_work_orders_count: submitted_work_orders_count}}) do
    Reading.work_orders_submitted(submitted_work_orders_count)
  end
end
