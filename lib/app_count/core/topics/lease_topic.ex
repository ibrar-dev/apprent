defmodule AppCount.Core.LeaseTopic do
  @moduledoc """
  LeaseTopic maintains the event names
  and the name of the topic.
  The API section shows what it can do
  """

  alias AppCount.Core.DomainEvent
  alias AppCount.Core.EventBus

  # -- API ---------
  def created(%{lease_id: lease_id, tenant_id: tenant_id}, source) do
    %{
      event(:created)
      | content: %{tenant_id: tenant_id},
        source: source,
        subject_name: "AppCount.Leases.Lease",
        subject_id: lease_id
    }
    |> EventBus.publish()
  end

  # --- Event Builders ---
  def event(:created),
    do: %DomainEvent{name: "created", topic: topic()}

  #  --- General ---
  def topic, do: "leases__leases"

  def subscribe do
    EventBus.subscribe(topic())
  end
end
