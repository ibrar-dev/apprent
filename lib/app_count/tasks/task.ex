defmodule AppCount.Tasks.Task do
  def log(message) do
    Process.send(self(), {:log, message}, [:noconnect])
  end
end
