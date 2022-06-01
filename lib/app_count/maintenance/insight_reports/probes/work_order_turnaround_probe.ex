defmodule AppCount.Maintenance.InsightReports.WorkOrderTurnaroundProbe do
  @moduledoc """
  Given all non-make-ready work orders either currently open or completed in the
  specified time range, what is the average length of time each of those orders
  was (or has been) open?
  """
  use AppCount.Maintenance.InsightReports.ProbeBehaviour

  @impl ProbeBehaviour
  def mood, do: :neutral

  @impl ProbeBehaviour
  def insight_item(%ProbeContext{} = context) do
    reading = reading(context)

    comments = comments(reading.measure)

    %InsightItem{
      comments: comments,
      reading: reading,
      meta: %{mood: mood(), reporter: __MODULE__}
    }
  end

  @doc """
  Calculate average open duration in seconds
  """
  def call(orders, date_range) do
    without_make_ready =
      orders
      |> Enum.reject(fn o -> o.category.parent.name == "Make Ready" end)

    open_order_durations = open_order_durations(without_make_ready)
    completed_order_durations = completed_order_durations(without_make_ready, date_range)

    all = open_order_durations ++ completed_order_durations

    {result, :seconds} = average_seconds(all)

    result
  end

  @impl ProbeBehaviour
  def reading(%ProbeContext{input: %{orders: orders, date_range: date_range}}) do
    call(orders, date_range)
    |> Reading.work_order_turnaround()
  end

  def round_to_fractional_days(seconds) do
    seconds
    |> Duration.to_days()
    |> Duration.to_seconds()
  end

  @doc """
  Given our list of orders, get just the ones completed in the time range and
  determine how long they were open.
  """
  def completed_order_durations(orders, date_range) do
    orders
    |> Enum.filter(fn order -> order.status == "completed" end)
    |> Enum.map(fn order -> {order.inserted_at, completion_time(order)} end)
    |> Enum.filter(fn {_started, finished} -> within_range?(finished, date_range) end)
    |> Enum.map(fn {started, finished} -> Timex.diff(finished, started, :seconds) end)
  end

  def within_range?(timestamp, range) do
    Timex.after?(timestamp, range.from) and Timex.before?(timestamp, range.to)
  end

  @doc """
  Given an order, determine when it was completed and return that datetime. If
  no completion (for whatever reason), we return `nil`
  """
  def completion_time(order) do
    order.assignments
    |> Enum.map(fn o -> o.completed_at end)
    |> Enum.max(fn -> nil end)
  end

  @doc """
  Given a list of 0 or more Orders, find just the assigned/unassigned ones (the
  "open" orders) and determine how long they've been open. We'll get back a list
  """
  def open_order_durations(orders) do
    now = Timex.now()

    orders
    |> Enum.filter(fn order -> order.status in ["assigned", "unassigned"] end)
    |> Enum.map(fn order -> Timex.diff(now, order.inserted_at, :seconds) end)
  end

  defp average_seconds([]) do
    {0, :seconds}
  end

  defp average_seconds(items) do
    result = Enum.sum(items) / length(items)
    {result, :seconds}
  end

  def comments(nil) do
    []
  end

  def comments({nil, :seconds}) do
    []
  end

  def comments({0, :seconds}) do
    []
  end

  def comments({0.0, :seconds}) do
    []
  end

  def comments({seconds, :seconds} = measurement) when is_number(seconds) do
    {average_days, :days} = measurement |> Duration.to_days()

    cond do
      average_days == 1 ->
        str =
          "Great job! Our average work order was only open for 1 day. " <>
            "Your residents appreciate this!"

        [str]

      average_days < 2 ->
        str =
          "Great job! Our average work order was only open for #{average_days} days. " <>
            "Your residents appreciate this!"

        [str]

      average_days > 5 ->
        str =
          "On average our work orders are open for #{average_days} days. " <>
            "Let's work to bring this down to under 2 days"

        [str]

      true ->
        []
    end
  end
end
