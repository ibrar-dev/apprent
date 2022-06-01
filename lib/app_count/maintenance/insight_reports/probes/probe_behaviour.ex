defmodule AppCount.Maintenance.InsightReports.ProbeBehaviour do
  @callback insight_item(AppCount.Maintenance.InsightReports.ProbeContext.t()) ::
              AppCount.Maintenance.InsightItem.t()

  @callback reading(AppCount.Maintenance.InsightReports.ProbeContext.t()) ::
              AppCount.Maintenance.Reading.t()

  @callback mood() :: atom()

  defmacro __using__(_) do
    quote do
      alias AppCount.Maintenance.InsightReports.ProbeContext
      alias AppCount.Core.DateTimeRange
      alias AppCount.Maintenance.InsightReports.Duration
      alias AppCount.Maintenance.InsightItem
      alias AppCount.Maintenance.Reading
      alias AppCount.Maintenance.InsightReports.ProbeBehaviour
      @behaviour AppCount.Maintenance.InsightReports.ProbeBehaviour
    end
  end
end
