defmodule AppCount.TwilioSupervisor do
  use Supervisor

  def start_link(_opts \\ []) do
    AppCount.GenserverLogger.starting(__MODULE__)
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      AppCount.Adapters.TwilioExternalService,
      {AppCount.Core.Ports.TwilioPort, AppCount.Core.Ports.TwilioPort}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
