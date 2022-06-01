defmodule AppCount.Properties.Server.PropertyServer do
  @moduledoc """
  Run one server per Property, holds the tree of connected structs for a Property
  The connections do not change during the day, but the data might change.
  You can use this to look up connections, but then get fresh data from the DB using the provided ids.

  """
  use GenServer
  require Logger
  alias AppCount.Properties.Server.MiniProperty
  alias AppCount.Core.DomainEvent

  # ---------  Client Interface  -------------

  def start_link(property_id) when is_integer(property_id) do
    GenServer.start_link(__MODULE__, property_id, name: via_tuple(property_id))
  end

  def load(property_id) do
    GenServer.call(via_tuple(property_id), :load)
  end

  def current_tenant_ids(property_id) when is_integer(property_id) do
    GenServer.call(via_tuple(property_id), :current_tenant_ids)
  end

  def unit_ids(property_id) when is_integer(property_id) do
    GenServer.call(via_tuple(property_id), :unit_ids)
  end

  def setting(property_id) when is_integer(property_id) do
    GenServer.call(via_tuple(property_id), :setting)
  end

  def has_tenant?(property_id, tenant_id)
      when is_integer(property_id) and is_integer(tenant_id) do
    GenServer.call(via_tuple(property_id), {:has_tenant?, tenant_id})
  end

  def unit_lease_tenant(property_id, tenant_id)
      when is_integer(property_id) and is_integer(tenant_id) do
    GenServer.call(via_tuple(property_id), {:unit_lease_tenant, tenant_id})
  end

  def shut_down(property_id) when is_integer(property_id) do
    GenServer.stop(via_tuple(property_id))
    Process.sleep(200)
  end

  def alive?(property_id) when is_integer(property_id) do
    pid_or_nil = GenServer.whereis(via_tuple(property_id))
    !!pid_or_nil
  end

  # ---------  Server  -------------

  def init(property_id) when is_integer(property_id) do
    AppCount.GenserverLogger.starting(__MODULE__, "property_id(#{property_id})")
    property = %MiniProperty{id: property_id}
    {:ok, property, {:continue, :load_data}}
  end

  # ---------------------------------------------------------------- reload handlers
  # For the timer
  def handle_info(:load, %MiniProperty{id: property_id}) do
    state = reload(property_id)
    {:noreply, state, :hibernate}
  end

  def handle_info(
        %DomainEvent{name: "property_changed", content: %{property_id: property_id}},
        _discarded_state
      ) do
    state = reload(property_id)
    {:noreply, state}
  end

  # For init
  def handle_continue(:load_data, %MiniProperty{id: property_id}) do
    state = reload(property_id)
    {:noreply, state}
  end

  # For the client to call
  def handle_call(:load, _from, %MiniProperty{id: property_id}) do
    state = reload(property_id)
    {:reply, :ok, state}
  end

  # ---------------------------------------------------------------- handlers

  def handle_call(:unit_ids, _from, %MiniProperty{units: units} = property) do
    unit_ids = units |> Enum.map(fn unit -> unit.id end)
    {:reply, unit_ids, property}
  end

  def handle_call(:current_tenant_ids, _from, %MiniProperty{} = property) do
    current_tenant_ids = MiniProperty.current_tenant_ids(property)

    {:reply, current_tenant_ids, property}
  end

  def handle_call(:setting, _from, %MiniProperty{setting: setting} = property) do
    {:reply, setting, property}
  end

  def handle_call({:has_tenant?, tenant_id}, _from, %MiniProperty{} = property) do
    tenant = MiniProperty.tenant(property, tenant_id)
    true_or_false = tenant != :not_found
    {:reply, true_or_false, property}
  end

  def handle_call({:unit_lease_tenant, tenant_id}, _from, %MiniProperty{} = property) do
    result =
      case MiniProperty.unit_lease_tenant(property, tenant_id) do
        {unit, lease, tenant} ->
          {:ok, {unit.id, lease.id, tenant.id}}

        :not_found ->
          {:error, "Not Found unit_lease_tenant, tenant_id:#{tenant_id}"}

        error ->
          {:error, "Error unit_lease_tenant, tenant_id:#{tenant_id} #{inspect(error)}"}
      end

    {:reply, result, property}
  end

  # ----------  Implementation ------

  def reload(property_id) do
    property = MiniProperty.load_property(property_id)
    schedule_next_load()
    property
  end

  def schedule_next_load do
    minute_in_milliseconds = 60 * 1000
    five_minute_in_milliseconds = minute_in_milliseconds * 5
    hour_in_milliseconds = minute_in_milliseconds * 60

    drift = Enum.random(1..five_minute_in_milliseconds)
    interval = hour_in_milliseconds + drift
    Process.send_after(self(), :load, interval)
  end

  defp via_tuple(property_id) do
    {:via, Registry, {AppCount.Registry, "property_id:#{property_id}"}}
  end
end
