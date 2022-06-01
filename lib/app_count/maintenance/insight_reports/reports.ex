defmodule AppCount.Maintenance.InsightReports.Reports do
  alias AppCount.Maintenance.InsightReportSubscriptions
  alias AppCount.Maintenance.InsightReports
  alias AppCount.Maintenance.InsightReports.Daily
  alias AppCount.Maintenance.InsightReports.ReportMailer
  alias AppCount.Maintenance.InsightReports.ReportManager
  alias AppCount.Properties
  alias AppCount.Properties.Property
  alias AppCount.Properties.Setting
  alias AppCount.Repo
  import Ecto.Query
  alias AppCount.Core.ClientSchema

  @doc """
  Given a property and timestamp, figure out if we need to send a report.

  Then send one (or don't).

  Returns :ok
  """
  def make_and_send(type) do
    # Only get active properties
    property_ids =
      Repo.all(
        from p in Property,
          join: s in Setting,
          on: s.property_id == p.id,
          where: s.active,
          select: p.id
      )

    # We do the sending asynchronously
    property_ids
    |> Enum.each(fn id -> ReportManager.make_and_send(id, type) end)
  end

  # Actually generate the reports in question and email 'em off.
  def make_and_send(property_id, type) when type == "daily" do
    prop = Properties.get_property(ClientSchema.new("dasmen", property_id))

    time_zone = prop.time_zone

    {:ok, now} = DateTime.now(time_zone)

    candidate_report = InsightReports.fetch_for_day(prop, now, type)

    # Get us 5pm, please!
    report_time =
      now
      |> Timex.beginning_of_day()
      |> Timex.set(hour: 17)

    # Generate a report assuming no report exists and we're past 5p for the day
    if is_nil(candidate_report) and not Timex.before?(now, report_time) do
      with {:ok, report} <- generate_daily_report(prop, report_time) do
        # Only send if M-F
        if Timex.weekday(report_time) in 1..5 do
          subscriber_ids = InsightReportSubscriptions.admin_ids_for(report)
          ReportMailer.send_daily(report.id, subscriber_ids)
        end

        report
      end
    else
      nil
    end
  end

  @doc """
  Generate Daily report and save to DB - should return {:ok, %InsightReport{}} or {:error, err}
  """
  def generate_daily_report!(property_id, cutoff) when is_number(property_id) do
    # TODO:SCHEMA remoec dasmen

    prop = Properties.get_property(ClientSchema.new("dasmen", property_id))

    generate_daily_report(prop, cutoff)
  end

  def generate_daily_report(%Property{} = property, cutoff) do
    report = generate_daily_stats(property, cutoff)

    attrs = %{
      property_id: property.id,
      start_time: report.start_datetime,
      end_time: report.end_datetime,
      type: "daily",
      data: report.data
    }

    # TODO:SCHEMA remoec dasmen
    InsightReports.create(ClientSchema.new("dasmen", attrs))
  end

  @doc """
  Generate the stats for a daily insight report for a given property with
  cut-off of timestamp

  - property - %AppCount.Properties.Property{} struct
  - cutoff_timestamp - UTC timestamp
  """
  def generate_daily_stats(%Property{} = property, cutoff_timestamp) do
    date_range =
      AppCount.Core.DateTimeRange.new(one_day_prior(cutoff_timestamp), cutoff_timestamp)

    Daily.generate_stats(property, date_range)
  end

  # Given a DateTime, go 1 day prior
  defp one_day_prior(timestamp) do
    Timex.shift(timestamp, days: -1)
  end
end
