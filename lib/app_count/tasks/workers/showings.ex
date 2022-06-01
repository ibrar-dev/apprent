defmodule AppCount.Tasks.Workers.ShowingReminderEmails do
  alias AppCount.Repo
  alias AppCount.Prospects.Showing
  import Ecto.Query
  use AppCount.Tasks.Worker, "Send showing reminder emails"

  @impl AppCount.Tasks.Worker
  def perform(schema \\ "dasmen") do
    from(
      s in Showing,
      join: property in assoc(s, :property),
      left_join: logo in assoc(property, :logo_url),
      join: p in assoc(s, :prospect),
      select: %{
        id: s.id,
        date: s.date,
        start_time: s.start_time,
        property: merge(property, %{logo: logo.url}),
        name: p.name,
        email: p.email
      },
      where: fragment("current_date - ? = -1", s.date) and is_nil(s.cancellation)
    )
    |> Repo.all(prefix: schema)
    |> Enum.each(&AppCountCom.Showings.showing_reminder_email/1)
  end
end
