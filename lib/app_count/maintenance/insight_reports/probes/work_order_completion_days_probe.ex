defmodule AppCount.Maintenance.InsightReports.WorkOrderCompletionDaysProbe do
  use AppCount.Maintenance.InsightReports.ProbeBehaviour
  @day_in_seconds 24 * 60 * 60

  @moduledoc """
  Given a property, start_time, and end_time, calculate average completion time
  for all jobs completed within that timespan (inclusive)

  Value is returned in seconds
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
  def reading(%ProbeContext{input: %{completion_time: completion_time}}) do
    average_completion_time = call(completion_time)

    Reading.work_order_completion_days(average_completion_time)
  end

  def comments(average_completion_days) do
    formatted_time = Duration.display({average_completion_days, :seconds})

    cond do
      is_binary(average_completion_days) ->
        []

      is_nil(average_completion_days) ->
        []

      average_completion_days < 2 * @day_in_seconds ->
        str =
          "Great job! You are averaging a completion time of #{formatted_time}. " <>
            "Your residents appreciate this!"

        [str]

      average_completion_days > 5 * @day_in_seconds ->
        str =
          "Our average completion time is #{formatted_time}. " <>
            "Let's work to bring this down to under 2 days"

        [str]

      true ->
        []
    end
  end

  def call(completion_time) do
    if is_nil(completion_time) do
      "No Data"
    else
      completion_time
    end
  end
end
