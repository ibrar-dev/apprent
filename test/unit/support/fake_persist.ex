defmodule AppCount.Support.FakePersist do
  def persist(_key, state) do
    state
  end

  def fetch(_key), do: nil
end
