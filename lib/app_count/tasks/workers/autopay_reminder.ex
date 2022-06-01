defmodule AppCount.Tasks.Workers.AutopayReminder do
  use AppCount.Tasks.Worker, "Send Autopay Reminder Emails"
  alias AppCount.Accounts.Autopays.SendReminder

  @impl AppCount.Tasks.Worker
  def perform(schema \\ "dasmen") do
    SendReminder.perform(schema)
  end
end
