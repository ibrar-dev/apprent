defmodule AppCount.Maintenance.InsightReports do
  alias AppCount.Maintenance.InsightReport
  alias AppCount.Properties.Property
  alias AppCount.Repo
  import Ecto.Query

  @moduledoc """
  Let's deal with our insight reports, please
  """

  def insight_items(probes, probe_context) do
    probes
    |> Enum.reduce([], fn module, acc ->
      probe = Module.concat(["AppCount.Maintenance.InsightReports", module])
      insight_item = probe.insight_item(probe_context)
      [insight_item | acc]
    end)
    |> Enum.reverse()
  end

  # Grab a single insight report
  def fetch(id) do
    Repo.one(
      from i in InsightReport,
        where: i.id == ^id,
        limit: 1,
        preload: [:property]
    )
    |> atomize_keys()
  end

  # We send out reports at 5p local time for each day - this query checks to see
  # if a report for the given type has gone out for a given day and returns
  # either the report or nil
  def fetch_for_day(%Property{} = property, datetime, type) do
    beginning_of_day = Timex.beginning_of_day(datetime)
    end_of_day = Timex.end_of_day(datetime)

    Repo.one(
      from i in InsightReport,
        where:
          i.property_id == ^property.id and i.end_time >= ^beginning_of_day and
            i.end_time <= ^end_of_day and i.type == ^type,
        limit: 1
    )
  end

  # Give us the report's date, formatted for property's local time
  def formatted_date(report) do
    timestamp = report.end_time
    timezone = report.property.time_zone

    adjusted_time = Timex.Timezone.convert(timestamp, timezone)

    # If we ever allow reports to be sent at different times, we'll want to
    # adjust the strftime string to "%Y-%m-%d %I:%M %p %Z"
    Timex.format!(adjusted_time, "%Y-%m-%d", :strftime)
  end

  def formatted_time(report) do
    timestamp = report.end_time
    timezone = report.property.time_zone

    adjusted_time = Timex.Timezone.convert(timestamp, timezone)

    Timex.format!(adjusted_time, "%Y-%m-%d %I:%M %p %Z", :strftime)
  end

  # Possible filter criteria:
  #
  # - property_ids - list of property primary key ids (int)
  # - type - "weekly" or "daily"
  # - start_date - date
  # - start_date - date
  def index(filter_criteria \\ %{}) do
    query =
      from(
        i in InsightReport,
        order_by: [desc: i.end_time, desc: i.property_id, desc: i.type],
        preload: [:property]
      )

    query =
      Enum.reduce(filter_criteria, query, fn
        {:property_ids, property_ids}, query ->
          from q in query, where: q.property_id in ^property_ids

        {:type, "daily"}, query ->
          from q in query, where: q.type == "daily"

        {:type, "weekly"}, query ->
          from q in query, where: q.type == "weekly"

        {:type, _}, query ->
          query

        # For start_date and end_date, we're looking at the "issued_at" field,
        # which is proxied by the end date. So the range gives us all reports that
        # ended between start_date (start of day) and end_date (end of day)
        {:start_date, %Date{} = start_date}, query ->
          start_time =
            start_date
            |> Timex.to_datetime()
            |> Timex.beginning_of_day()

          from q in query, where: q.end_time >= ^start_time

        {:start_date, _}, query ->
          query

        {:end_date, %Date{} = end_date}, query ->
          end_time =
            end_date
            |> Timex.to_datetime()
            |> Timex.end_of_day()

          from q in query, where: q.end_time <= ^end_time

        {:end_date, _}, query ->
          query

        _, query ->
          query
      end)

    Repo.all(query)
    |> Enum.map(&atomize_keys/1)
  end

  # Create an insight report
  #
  # Params:
  # + data - map
  # + start_time - utc
  # + end_time - utc
  # + property_id
  # + type
  def create(%AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: attrs
      }) do
    %InsightReport{}
    |> InsightReport.changeset(attrs)
    |> Repo.insert(prefix: client_schema)
  end

  # recursively convert string keys to atom keys for our data column - this
  # helps to make presentation of these reports (and access of data) consistent
  # throughout the application, assuming we always go through this module for
  # access.
  def atomize_keys(%InsightReport{} = report) do
    data = report.data
    {:ok, new_data} = Morphix.atomorphiform(data)

    %{report | data: new_data}
  end

  # Fallback
  def atomize_keys(any) do
    any
  end
end
