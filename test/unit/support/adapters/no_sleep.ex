defmodule AppCount.Support.Adapters.NoSleep do
  def sleep(_milliseconds) do
    # continue without sleeping
  end
end
