defmodule AppCount.Core.SoftLedgerTranslationTopic do
  @moduledoc """
  SoftLedgerTranslationTpoic maintains the event names
  and the name of the topic.
  The API section shows what it can do
  """
  @behaviour AppCount.Core.RepoTopicBehaviour

  alias AppCount.Core.DomainEvent
  alias AppCount.Core.EventBus

  # -- API ---------
  @impl AppCount.Core.RepoTopicBehaviour
  def created(meta, source) do
    %{event(:created) | content: %{}, source: source}
    |> Map.merge(meta)
    |> EventBus.publish()
  end

  @impl AppCount.Core.RepoTopicBehaviour
  def changed(meta, source) do
    %{event(:changed) | content: %{}, source: source}
    |> Map.merge(meta)
    |> EventBus.publish()
  end

  @impl AppCount.Core.RepoTopicBehaviour
  def deleted(meta, source) do
    %{event(:deleted) | content: %{}, source: source}
    |> Map.merge(meta)
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
  def topic, do: "soft_ledger__translations"

  def subscribe do
    EventBus.subscribe(topic())
  end
end
