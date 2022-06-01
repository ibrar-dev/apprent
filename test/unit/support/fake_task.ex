defmodule AppCount.Tasks.Workers.FakeTask do
  use AppCount.Tasks.Worker, "Fake task for testing"

  @impl AppCount.Tasks.Worker
  def perform() do
  end
end
