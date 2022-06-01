defmodule AppCount.GenserverLogger do
  require Logger

  def starting(module, note \\ "") do
    Logger.info("Starting GenServer #{module}, #{note}")
  end

  def stopping(module, note \\ "") do
    Logger.info("Stopping GenServer #{module}, #{note}")
  end
end
