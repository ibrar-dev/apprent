defmodule AppCount.Core.Ports.RequestBehaviour do
  @callback new(map()) :: struct()
  @callback verb() :: atom
  @callback path(String.t(), integer()) :: String.t()
  @callback returning() :: atom
end
