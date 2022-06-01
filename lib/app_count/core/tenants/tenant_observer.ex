defmodule AppCount.Core.TenantObserver do
  @moduledoc """
  Listen to TenantRepo insert, update, and delete events
  """
  use GenServer
  alias AppCount.Core.DomainEvent
  alias AppCount.Core.TenantTopic
  alias AppCount.Core.TenantObserver.State
  require Logger

  # --- CLIENT INTERFACE ----------------------------------
  def start_link([]) do
    state = %State{}
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def start_link(name: name) do
    state = %State{}
    GenServer.start_link(__MODULE__, state, name: name)
  end

  def invalid_phone_numbers do
    GenServer.call(__MODULE__, :invalid_phone_numbers)
  end

  #  --- SERVER INTERFACE -------------------------------------
  def init(%State{} = state) do
    AppCount.GenserverLogger.starting(__MODULE__)
    TenantTopic.subscribe()
    AppCount.Core.SmsTopic.subscribe()

    {:ok, state, {:continue, :load_phone_tenant_map}}
  end

  # ===========================================================  handle_continue
  def handle_continue(
        :load_phone_tenant_map,
        %State{deps: %{state: state_module}} = state
      ) do
    state = state_module.load_phone_tenant_map(state)
    {:noreply, state}
  end

  # =========================================================== handle_call
  def handle_call(:invalid_phone_numbers, _, state) do
    phone_numbers =
      state.phone_tenant_map
      |> Map.keys()

    {:reply, phone_numbers, state}
  end

  # =========================================================== handle_info
  #
  # tenant changes to payment_status: cash
  def handle_info(
        %DomainEvent{
          topic: "tenants__tenants",
          name: "changed",
          content: %{changes: %{payment_status: "cash"}},
          subject_name: "AppCount.Tenants.Tenant",
          subject_id: tenant_id
        },
        %State{deps: %{state: state_module}} = state
      ) do
    state_module.payment_status_changed_to_cash(tenant_id, state)
    {:noreply, state}
  end

  # tenant activates autopay
  def handle_info(
        %DomainEvent{
          topic: "tenants__tenants",
          name: "changed",
          content: %{changes: %{active: true}},
          subject_name: "AppCount.Tenants.Tenant",
          subject_id: tenant_id
        },
        %State{deps: %{state: state_module}} = state
      ) do
    state_module.autopay_activated_notification(tenant_id, state)
    {:noreply, state}
  end

  # tenant deactivates autopay
  def handle_info(
        %DomainEvent{
          topic: "tenants__tenants",
          name: "changed",
          content: %{changes: %{active: false}},
          subject_name: "AppCount.Tenants.Tenant",
          subject_id: tenant_id
        },
        %State{deps: %{state: state_module}} = state
      ) do
    state_module.autopay_deactivated_notification(tenant_id, state)
    {:noreply, state}
  end

  # tenant invalid_phone_number
  def handle_info(
        %DomainEvent{
          topic: "sms",
          name: "invalid_phone_number",
          content: %{phone: phone}
        },
        %State{deps: %{state: state_module} = state}
      ) do
    state = state_module.update_invalid_phone_numbers(%{phone: phone}, state)
    {:noreply, state}
  end

  # skip uninteresting DomainEvents
  def handle_info(%DomainEvent{} = _domain_event, state) do
    {:noreply, state}
  end

  # ------------  Implementation -----------------------
end
