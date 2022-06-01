defmodule AppCount.Maintenance.InsightReports.WorkOrderOpenProbe do
  use AppCount.Maintenance.InsightReports.ProbeBehaviour

  @moduledoc """
  Given property, count open work orders.  For our use case, open counts as
  "neither completed nor canceled." Ignores Make-Ready orders
  """
  def call(open_orders) do
    count = Enum.count(open_orders)
    {count, :count}
  end

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
  def reading(%ProbeContext{
        input: %{open_orders: open_orders}
      }) do
    {count, :count} = call(open_orders)

    Reading.work_orders(count)
  end
end
