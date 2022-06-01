defmodule AppCount.Maintenance.InsightReports.ReportMailer do
  alias AppCount.Maintenance.InsightReports
  alias AppCount.Repo
  alias AppCount.Core.ClientSchema

  # Report ID will be for a report's id
  # recipient_ids will be a list of Admin IDs
  #
  # Returns :ok
  def send_daily(report_id, recipient_ids) when is_list(recipient_ids) do
    Enum.each(recipient_ids, fn id -> send_daily(report_id, id) end)
  end

  # report will be an AppCount.Maintenance.InsightReport
  # recipient will be an AppCount.Admins.Admin
  #
  # If the Recipient (or report or property) cannot be found, we simply do not
  # send the email and return the appropriate error.
  def send_daily(report_id, recipient_id) do
    with {:ok, report} <- fetch_report(report_id),
         {:ok, property} <- fetch_property(report.property_id),
         {:ok, recipient} <- fetch_recipient(recipient_id) do
      AppCountCom.InsightReports.daily_insight_report(
        recipient.email,
        recipient.name,
        property,
        report
      )

      # Everything is fine
      :ok
    else
      # Nothing is fine
      err -> err
    end
  end

  def fetch_recipient(id) do
    admin = Repo.get(AppCount.Admins.Admin, id)

    if admin do
      {:ok, admin}
    else
      {:error, "admin not found"}
    end
  end

  # This one is different because get_property/1 blows up if it can't find the
  # property -- shouldn't be an issue with how we're calling things above.
  # Ordinarily I'd preload the property, but our email templates seem to have a
  # dependency with this particular representation of Properties.
  def fetch_property(id) do
    property = AppCount.Properties.get_property(ClientSchema.new("dasmen", id))

    {:ok, property}
  end

  defp fetch_report(id) do
    report = InsightReports.fetch(id)

    if report do
      {:ok, report}
    else
      {:error, "report not found"}
    end
  end
end
