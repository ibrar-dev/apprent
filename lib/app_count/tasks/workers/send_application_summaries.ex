defmodule AppCount.Tasks.Workers.SendApplicationSummaries do
  use AppCount.Tasks.Worker, "Send application summaries"

  @impl AppCount.Tasks.Worker
  def perform(schema \\ "dasmen") do
    AppCount.Repo.all(AppCount.Admins.Admin, prefix: schema)
    |> Enum.each(fn admin ->
      from_date = one_week_ago()
      applications = AppCount.RentApply.list_applications(admin, from_date)
      AppCountCom.Applications.application_summary(admin, from_date, applications)
    end)
  end

  defp one_week_ago() do
    AppCount.current_time()
    |> Timex.shift(days: -7)
    |> Timex.beginning_of_day()
  end
end
