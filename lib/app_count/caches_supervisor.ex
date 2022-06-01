defmodule AppCount.CachesSupervisor do
  @moduledoc """
  These gen_servers act as DB caches.
  """
  use Supervisor

  def start_link(_opts \\ []) do
    AppCount.GenserverLogger.starting(__MODULE__)
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      AppCount.Properties.Server.PropertyServerSupervisor,
      AppCount.Properties.Server.PropertiesServer,
      AppCount.Admins.AccessServer
      #      AppCount.Public.ClientFeaturesCache
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end
end
