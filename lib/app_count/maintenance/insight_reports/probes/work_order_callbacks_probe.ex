defmodule AppCount.Maintenance.InsightReports.WorkOrderCallbacksProbe do
  alias AppCount.Maintenance.Order
  alias AppCount.Maintenance.Tech
  alias AppCount.Properties.Unit
  alias AppCount.Maintenance.Assignment

  use AppCount.Maintenance.InsightReports.ProbeBehaviour

  @impl ProbeBehaviour
  def mood, do: :negative

  @impl ProbeBehaviour
  def insight_item(
        %ProbeContext{
          input: %{callback_assignments: callback_assignments}
        } = context
      ) do
    comments = comments(callback_assignments)
    reading = reading(context)

    %InsightItem{
      comments: comments,
      reading: reading,
      meta: %{mood: mood(), reporter: __MODULE__}
    }
  end

  @impl ProbeBehaviour
  def reading(%ProbeContext{input: %{callback_assignments: callback_assignments}}) do
    result_count = Enum.count(callback_assignments)
    Reading.work_order_callbacks(result_count)
  end

  def comments(callback_assignments) do
    callback_assignments
    |> Enum.reduce([], fn assignment, acc -> [interpolate_comment(assignment) | acc] end)
  end

  def interpolate_comment(%Assignment{
        order: %Order{
          id: order_id,
          unit: %Unit{number: unit_number}
        },
        tech: %Tech{name: tech_name}
      }) do
    "We received a callback for work order #{order_id} at unit #{unit_number} completed by #{
      tech_name
    }. Please address this."
  end

  def call(callback_assignments) do
    callback_assignments
  end
end
