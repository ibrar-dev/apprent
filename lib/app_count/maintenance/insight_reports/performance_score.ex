defmodule AppCount.Maintenance.InsightReports.PerformanceScore do
  alias AppCount.Maintenance.InsightReports.PerformanceScore
  alias AppCount.Maintenance.InsightReports.ProbeContext
  alias AppCount.Maintenance.InsightReports.Duration
  alias AppCount.Maintenance.Reading
  alias AppCount.Maintenance.InsightReports.PerformancePoints, as: Points

  defstruct [
    :property_name,
    :work_order_saturation,
    :callbacks,
    :violations,
    :ratings,
    :work_order_turnaround,
    :make_ready_turnaround,
    :make_ready_percent,
    :make_ready_utilization
  ]

  def performance_probes() do
    ~w[
      PropertyNameProbe
      UnitCountProbe

      WorkOrderCallbacksProbe
      WorkOrderViolationsProbe
      WorkOrderRatingProbe
      WorkOrderSaturationProbe
      WorkOrderTurnaroundProbe

      MakeReadyTurnaroundProbe
      MakeReadyPercentageProbe
      MakeReadyUtilizationProbe
    ]
  end

  def best_score do
    %PerformanceScore{
      property_name: "Best Score",
      work_order_saturation: 25.0,
      callbacks: 7.5,
      violations: 7.5,
      ratings: 5.0,
      work_order_turnaround: 15.0,
      make_ready_turnaround: 15.0,
      make_ready_percent: 15.0,
      make_ready_utilization: 15.0
    }
  end

  def worst_score do
    %PerformanceScore{
      property_name: "Worst Score",
      work_order_saturation: 0.0,
      callbacks: 0,
      violations: 0,
      ratings: 0,
      work_order_turnaround: 0,
      make_ready_turnaround: 0,
      make_ready_percent: 0.0,
      make_ready_utilization: 0.0
    }
  end

  def readings(%ProbeContext{} = probe_context) do
    performance_probes()
    |> Enum.reduce([], fn module, acc ->
      probe = Module.concat(["AppCount.Maintenance.InsightReports", module])
      reading = probe.reading(probe_context)
      [reading | acc]
    end)
    |> Enum.reverse()
  end

  def scale(%PerformanceScore{} = score) do
    total_score = score |> total()
    total_max = best_score() |> total()

    (total_score / total_max * 100.0)
    |> Float.round(2)
  end

  def total(%PerformanceScore{
        work_order_saturation: work_order_saturation,
        callbacks: callbacks,
        violations: violations,
        ratings: rating,
        work_order_turnaround: work_order_turnaround,
        make_ready_turnaround: make_ready_turnaround,
        make_ready_percent: make_ready_percent,
        make_ready_utilization: make_ready_utilization
      }) do
    work_order_saturation +
      callbacks +
      violations +
      rating +
      work_order_turnaround +
      make_ready_turnaround +
      make_ready_percent +
      make_ready_utilization
  end

  def from_readings(readings) when is_list(readings) do
    score = %PerformanceScore{}

    readings
    |> Enum.reduce(
      score,
      fn reading, score -> from_reading(reading, score) end
    )
  end

  def from_reading(%Reading{name: :property_name, measure: {property_name, :text}}, score)
      when is_binary(property_name) do
    %{score | property_name: property_name}
  end

  def from_reading(
        %Reading{name: :work_order_saturation, measure: {percent, :percent} = measure},
        score
      )
      when is_number(percent) do
    result = Points.work_order_saturation(measure)
    %{score | work_order_saturation: result}
  end

  def from_reading(
        %Reading{name: :work_order_callbacks, measure: {count, :count} = measure},
        score
      )
      when is_number(count) do
    result = Points.callbacks(measure)
    %{score | callbacks: result}
  end

  def from_reading(
        %Reading{name: :work_order_violations, measure: {count, :count} = measure},
        score
      )
      when is_number(count) do
    result = Points.violations(measure)
    %{score | violations: result}
  end

  def from_reading(
        %Reading{name: :work_order_rating, measure: {rating, :rating} = measure},
        score
      )
      when is_number(rating) do
    result = Points.ratings(measure)
    %{score | ratings: result}
  end

  def from_reading(
        %Reading{name: :work_order_turnaround, measure: {seconds, :seconds} = measure},
        score
      )
      when is_number(seconds) do
    result =
      measure
      |> Duration.to_days()
      |> Points.work_order_turnaround()

    %{score | work_order_turnaround: result}
  end

  def from_reading(
        %Reading{name: :make_ready_turnaround, measure: {seconds, :seconds} = measurement},
        score
      )
      when is_number(seconds) do
    result =
      measurement
      |> Duration.to_days()
      |> Points.make_ready_turnaround()

    %{score | make_ready_turnaround: result}
  end

  def from_reading(
        %Reading{name: :make_ready_percent, measure: {percent, :percent} = measurement},
        score
      )
      when is_number(percent) do
    result = Points.make_ready_percent(measurement)
    %{score | make_ready_percent: result}
  end

  def from_reading(
        %Reading{name: :make_ready_utilization, measure: {percent, :percent} = measurement},
        score
      )
      when is_number(percent) do
    result = Points.make_ready_utilization(measurement)
    %{score | make_ready_utilization: result}
  end

  # pass thru
  def from_reading(%Reading{name: :unit_count} = _reading, score) do
    score
  end
end
