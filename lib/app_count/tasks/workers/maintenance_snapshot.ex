defmodule AppCount.Tasks.Workers.MaintenanceSnapshot do
  use AppCount.Tasks.Worker, "Send out maintenance snapshot"

  @impl AppCount.Tasks.Worker
  def perform() do
    wday =
      AppCount.current_time()
      |> Timex.weekday()

    if wday in [1, 2, 3, 4, 5] do
      AppCount.Repo.all(AppCount.Admins.Admin)
      |> Enum.each(fn admin ->
        date = AppCount.current_time()
        properties = AppCount.Maintenance.admin_daily_snapshot(admin, date)
        AppCountCom.WorkOrders.daily_snapshot(admin, date, properties)
      end)
    end
  end
end
