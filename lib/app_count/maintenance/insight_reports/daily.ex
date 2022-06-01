defmodule AppCount.Maintenance.InsightReports.Daily do
  alias AppCount.Core.DateTimeRange
  alias AppCount.Maintenance.InsightReports
  alias AppCount.Maintenance.InsightReports.ProbeContext
  alias AppCount.Maintenance.Reading

  @moduledoc """
  Given a property, compile data necessary for the daily insight report.

  """
  @doc """
  Generate a structured map of stats

  + property - AppCount.Properties.Property struct
  DateTimeRange is 'from' yesterday at 5p local time;  'to': today at 5p local time
  """
  def generate_stats(
        %AppCount.Properties.Property{} = property,
        %DateTimeRange{} = date_range
      ) do
    probe_context =
      ProbeContext.load(property, date_range)
      |> apply_probes()

    readings = Reading.put_property(probe_context.reading, property.id)

    %{
      start_datetime: date_range.from,
      end_datetime: date_range.to,
      property: property,
      data: %{
        synopsis: readings,
        detail_comments: probe_context.comments
      }
    }
  end

  def apply_probes(%ProbeContext{} = probe_context) do
    daily_insight_probes()
    |> InsightReports.insight_items(probe_context)
    |> place_into_context(probe_context)
  end

  def place_into_context(insights, probe_context) do
    insights
    |> Enum.reduce(probe_context, fn insight_item, probe_context ->
      add_insight_item(probe_context, insight_item)
    end)
  end

  def daily_insight_probes() do
    [
      "TechNoOrdersProbe",
      "TechNoAssignmentProbe",
      "TechLowCompletionProbe",
      "TechBadRatingProbe",
      "TechGoodRatingProbe",
      "TechCompleted15Probe",
      "MakeReadyUtilizationProbe",
      "MakeReadyTurnaroundProbe",
      "MakeReadyPercentageProbe",
      "UnitVacantProbe",
      "UnitVacantNotReadyProbe",
      "UnitVacantReadyProbe",
      "WorkOrderCallbacksProbe",
      "WorkOrderViolationsProbe",
      "WorkOrderRatingProbe",
      "WorkOrderSaturationProbe",
      "WorkOrderTurnaroundProbe",
      "WorkOrderOpenProbe",
      "WorkOrderCompletedProbe",
      "WorkOrdersSubmittedProbe"
    ]
  end

  # Used to test one
  def report_insight_item(probe_context, probe) do
    insight_item = probe.insight_item(probe_context)
    add_insight_item(probe_context, insight_item)
  end

  defp add_insight_item(probe_context, insight_item) do
    probe_context
    |> add_comments(insight_item.comments)
    |> add_reading(insight_item.reading)
  end

  defp add_comments(probe_context, []) do
    probe_context
  end

  defp add_comments(%{comments: comments} = probe_context, new_comments) do
    new_comments = comments ++ new_comments
    %{probe_context | comments: new_comments}
  end

  defp add_reading(probe_context, %AppCount.Maintenance.Reading{title: ""} = _skip_empty_reading) do
    probe_context
  end

  defp add_reading(
         %{reading: reading} = probe_context,
         %AppCount.Maintenance.Reading{} = new_reading
       ) do
    %{probe_context | reading: [new_reading | reading]}
  end
end
