defmodule AppCount.YardiSupervisor do
  use Supervisor

  def start_link(_opts \\ []) do
    AppCount.GenserverLogger.starting(__MODULE__)
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      {Yardi.Gateway.Service, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
