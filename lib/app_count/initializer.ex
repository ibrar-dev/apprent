defmodule AppCount.Initializer do
  use GenServer, restart: :transient

  # Client interface -----------------------------------------
  def start_link(_) do
    AppCount.GenserverLogger.starting(__MODULE__)
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  # Server ---------------------------------------------------
  def init(_) do
    {:ok, %{}, {:continue, :init_data}}
  end

  def handle_continue(:init_data, state) do
    # Place holder for other startup tasks

    {:stop, :normal, state}
  end
end
