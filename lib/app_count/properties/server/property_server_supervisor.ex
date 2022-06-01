defmodule AppCount.Properties.Server.PropertyServerSupervisor do
  use DynamicSupervisor
  alias AppCount.Properties.Server.PropertyServer
  require Logger

  def start_link(_arg) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    AppCount.GenserverLogger.starting(__MODULE__)
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_property_server(property_id) when is_integer(property_id) do
    case DynamicSupervisor.start_child(__MODULE__, {PropertyServer, property_id}) do
      {:ok, pid} ->
        {:ok, pid}

      {:error, {:already_started, pid}} ->
        {:already_started, pid}

      error ->
        Logger.error("ERROR STARTING -------- #{inspect(property_id)} #{inspect(error)}")
        error
    end
  end
end
