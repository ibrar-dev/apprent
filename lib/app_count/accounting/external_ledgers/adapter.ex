defmodule AppCount.Accounting.ExternalLedgers.Adapter do
  alias AppCount.Accounting.ExternalLedgers.Subscribers.Property
  alias AppCount.Core.EventBus
  alias AppCount.Core.DomainEvent
  use GenServer

  @topic "external_ledger"
  # Client interface -----------------------------------------
  def start_link() do
    AppCount.GenserverLogger.starting(__MODULE__)
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  # Server ---------------------------------------------------
  def init(_) do
    EventBus.subscribe(@topic)
    {:ok, %{token: "LONG ASS TOKEN"}}
  end

  # Implementation -------------------------------------------
  def handle_info(%DomainEvent{name: "property_created"} = event, state) do
    Property.property_created(event)
    {:noreply, state}
  end

  def handle_info(%DomainEvent{name: "property_updated"} = event, state) do
    Property.property_updated(event)
    {:noreply, state}
  end

  def handle_info(%DomainEvent{name: "property_deleted"} = event, state) do
    Property.property_deleted(event)
    {:noreply, state}
  end
end
