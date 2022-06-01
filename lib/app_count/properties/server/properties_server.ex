defmodule AppCount.Properties.Server.PropertiesServer do
  @moduledoc """
  Run one server to query the other PropertyServers
  """
  use GenServer
  require Logger
  alias AppCount.Properties.Server.PropertiesServer
  alias AppCount.Properties.Server.PropertyServer
  alias AppCount.Properties.Server.PropertyServerSupervisor
  alias AppCount.Core.DomainEvent
  alias AppCount.Core.ClientSchema
  @property_repo AppCount.Properties.PropertyRepo

  defstruct active_property_ids: [],
            deps: %{property_server: PropertyServer, supervisor: PropertyServerSupervisor}

  # ---------  Client Interface  -------------

  def start_link(name: name) do
    GenServer.start_link(__MODULE__, name: name)
  end

  def start_link([]) do
    start_link(name: __MODULE__)
  end

  def shut_down(name) do
    try do
      GenServer.call(name, :shut_down)
    catch
      :exit, _value ->
        nil
    end
  end

  def active_property_ids() do
    GenServer.call(__MODULE__, :active_property_ids)
  end

  def property_unit_lease_tenant(tenant_id) do
    GenServer.call(__MODULE__, {:property_unit_lease_tenant, tenant_id})
  end

  # ---------  Server  -------------

  def init(_) do
    AppCount.GenserverLogger.starting(__MODULE__, "Global")
    AppCount.Core.PropertyTopic.subscribe()
    {:ok, %PropertiesServer{}, {:continue, :init_property_servers}}
  end

  # ---------------------------------------------------------------- handle_continue
  def handle_continue(:init_property_servers, _discarded_state) do
    state = load_active_properties(AppCount.Core.ClientSchema.new("dasmen"))

    state.active_property_ids
    |> Enum.each(fn property_id ->
      PropertyServerSupervisor.start_property_server(property_id)
    end)

    {:noreply, state}
  end

  # ---------------------------------------------------------------- handle_call
  def handle_call(
        {:property_unit_lease_tenant, tenant_id},
        _from,
        %PropertiesServer{
          active_property_ids: active_property_ids
        } = state
      ) do
    info_from_all_properties = multi_cast_unit_lease_tenant(active_property_ids, tenant_id)

    {:reply, info_from_all_properties, state}
  end

  def handle_call(
        :active_property_ids,
        _from,
        %PropertiesServer{active_property_ids: active_property_ids} = state
      ) do
    {:reply, active_property_ids, state}
  end

  # ---------------------------------------------------------------- handle_info
  def handle_info(
        %DomainEvent{name: "property_changed", content: %{property_id: property_id}},
        %PropertiesServer{
          active_property_ids: active_property_ids,
          deps: %{property_server: property_server}
        } = state
      ) do
    if Enum.member?(active_property_ids, property_id) do
      property_server.load(property_id)
    end

    {:noreply, state}
  end

  def handle_info(
        %DomainEvent{name: "property_created", content: %{property_id: property_id}},
        %PropertiesServer{
          active_property_ids: _active_property_ids,
          deps: %{supervisor: supervisor}
        } = state
      ) do
    supervisor.start_property_server(property_id)

    {:noreply, state}
  end

  #  -----------------------------------------------------------  implementation

  defp multi_cast_unit_lease_tenant(active_property_ids, tenant_id) do
    active_property_ids
    |> Enum.reduce([], fn property_id, acc ->
      case PropertyServer.unit_lease_tenant(property_id, tenant_id) do
        {:error, _message} ->
          acc

        {:ok, result} ->
          [Tuple.insert_at(result, 0, property_id) | acc]
      end
    end)
  end

  defp load_active_properties(%AppCount.Core.ClientSchema{name: client_schema, attrs: _}) do
    active_property_ids = @property_repo.active_property_ids(ClientSchema.new(client_schema, nil))
    %PropertiesServer{active_property_ids: active_property_ids}
  end
end
