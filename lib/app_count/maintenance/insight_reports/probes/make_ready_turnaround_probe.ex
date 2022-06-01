defmodule AppCount.Maintenance.InsightReports.MakeReadyTurnaroundProbe do
  alias AppCount.Maintenance.Card
  use AppCount.Maintenance.InsightReports.ProbeBehaviour
  @day_in_seconds 24 * 60 * 60

  @moduledoc """
  Given a property, start_time, and end_time, calculate average Make Ready time
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
  def reading(%ProbeContext{input: %{completed_cards: completed_cards}}) do
    make_ready_avg_seconds = call(completed_cards)

    Reading.make_ready_turnaround(make_ready_avg_seconds)
  end

  def comments(average_make_ready_completion_time) do
    formatted_time = Duration.display({average_make_ready_completion_time, :seconds})

    cond do
      is_binary(average_make_ready_completion_time) ->
        []

      is_nil(average_make_ready_completion_time) ->
        []

      average_make_ready_completion_time == 0 ->
        []

      average_make_ready_completion_time < 7 * @day_in_seconds ->
        str =
          "Phenomenal work on the turnaround time getting units ready!" <>
            " You are currently averaging #{formatted_time}."

        [str]

      average_make_ready_completion_time >= 14 * @day_in_seconds ->
        str =
          "Let's keep an eye on how much time it takes to get units ready. Right now we are averaging #{
            formatted_time
          }. " <>
            "Let's work to bring this down to under 7 days."

        [str]

      true ->
        []
    end
  end

  def call(completed_cards) do
    make_ready_times =
      completed_cards
      |> Enum.map(fn %Card{} = card -> extract_times(card) end)

    if make_ready_times == [] do
      0
    else
      make_ready_times
      |> Enum.map(fn x -> duration(x) end)
      |> average_seconds()
    end
  end

  defp extract_times(card) do
    %{
      start_time: card.move_out_date,
      end_time: Card.end_date(card)
    }
  end

  # Returns the duration of make ready jobs in seconds
  defp duration(%{start_time: start_time, end_time: end_time}) do
    start_time_eod = Timex.end_of_day(start_time)

    Timex.diff(end_time, start_time_eod, :seconds)
  end

  defp average_seconds([]) do
    0
  end

  defp average_seconds(list) do
    Enum.sum(list) / length(list)
  end
end
