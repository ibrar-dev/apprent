defmodule AppCount.Tasks.Workers.Autopay do
  alias AppCount.Accounts.ProcessAutopay
  use AppCount.Tasks.Worker, "Process autopay payments"

  @impl AppCount.Tasks.Worker
  def perform(schema \\ "dasmen") do
    ProcessAutopay.process(schema)
  end
end
