defmodule AppCount.Core.Sleeper do
  @sleeper AppCount.adapters(:sleeper, Process)

  def sleep(milliseconds) do
    @sleeper.sleep(milliseconds)
  end
end
