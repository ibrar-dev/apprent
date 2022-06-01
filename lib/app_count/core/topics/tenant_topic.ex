defmodule AppCount.Core.TenantTopic do
  @moduledoc """
  TenantTopic maintains the event names
  and the name of the topic.
  """
  @behaviour AppCount.Core.RepoTopicBehaviour

  alias AppCount.Core.RepoTopicBehaviour
  alias AppCount.Core.DomainEvent
  alias AppCount.Core.EventBus

  @impl RepoTopicBehaviour
  def created(%{subject_name: AppCount.Tenants.Tenant, subject_id: tenant_id}, source) do
    %{
      event(:created)
      | content: %{},
        source: source,
        subject_name: "AppCount.Tenants.Tenant",
        subject_id: tenant_id
    }
    |> EventBus.publish()
  end

  @impl RepoTopicBehaviour
  def changed(
        %{subject_id: tenant_id, subject_name: AppCount.Tenants.Tenant, changes: changes},
        source
      ) do
    %{
      event(:changed)
      | content: %{changes: changes},
        source: source,
        subject_name: "AppCount.Tenants.Tenant",
        subject_id: tenant_id
    }
    |> EventBus.publish()
  end

  @impl RepoTopicBehaviour
  def deleted(%{tenant_id: tenant_id}, source) do
    %{
      event(:deleted)
      | content: %{},
        source: source,
        subject_name: "AppCount.Tenants.Tenant",
        subject_id: tenant_id
    }
    |> EventBus.publish()
  end

  # --- Event Builders ---
  def event(:created),
    do: %DomainEvent{name: "created", topic: topic()}

  def event(:changed),
    do: %DomainEvent{name: "changed", topic: topic()}

  def event(:deleted),
    do: %DomainEvent{name: "deleted", topic: topic()}

  #  --- General ---
  def topic, do: "tenants__tenants"

  def subscribe do
    EventBus.subscribe(topic())
  end
end
