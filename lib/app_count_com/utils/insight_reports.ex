defmodule AppCountCom.InsightReports do
  import AppCountCom.Mailer.Sender, only: [send_email: 4]

  def daily_insight_report(email, recipient_name, property, %{data: data} = report) do
    # Given our report's time and the property's timezone, get the actual
    # issued date in local time rather than UTC
    d = report.end_time
    tz = Timex.Timezone.get(property.time_zone, report.end_time)
    issued_date = Timex.Timezone.convert(d, tz)

    weekday = Timex.format!(issued_date, "%A", :strftime)

    send_email(
      :daily_insight_report,
      {recipient_name, email},
      "[#{property.name}] Daily Maintenance Insight Report",
      property: property,
      data: data,
      issued_date: issued_date,
      recipient_name: recipient_name,
      weekday: weekday,
      report_id: report.id,
      layout: :admin
    )
  end
end
