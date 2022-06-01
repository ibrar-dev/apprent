defmodule AppCount.Core.FinanceAccountTopic do
  @moduledoc """
  For Financial Accounts
  FinanceAccountTopic maintains the event names
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

  # --- Event Names ---

  def name(:created), do: "created"
  def name(:changed), do: "changed"
  def name(:deleted), do: "deleted"

  # --- Event Builders ---
  def event(:created),
    do: %DomainEvent{name: name(:created), topic: topic()}

  def event(:changed),
    do: %DomainEvent{name: name(:changed), topic: topic()}

  def event(:deleted),
    do: %DomainEvent{name: name(:deleted), topic: topic()}

  #  --- General ---
  def topic, do: "finance__accounts"

  def subscribe do
    EventBus.subscribe(topic())
  end
end
