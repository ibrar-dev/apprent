defmodule AppCount.Core.PropertyTopic do
  @moduledoc """
  PropertyTopic maintains the event names
  and the name of the topic.
  The API section shows what it can do
  """

  alias AppCount.Core.DomainEvent
  alias AppCount.Core.EventBus

  # -- API ---------
  def property_created(%{} = info, source) do
    %{event(:property_created) | content: info, source: source}
    |> EventBus.publish()
  end

  def property_changed(%{} = info, source) do
    %{event(:property_changed) | content: info, source: source}
    |> EventBus.publish()
  end

  # --- Event Names ---

  def name(:property_created), do: "property_created"
  def name(:property_changed), do: "property_changed"

  # --- Event Builders ---
  def event(:property_created),
    do: %DomainEvent{name: name(:property_created), topic: topic()}

  def event(:property_changed),
    do: %DomainEvent{name: name(:property_changed), topic: topic()}

  #  --- General ---
  def topic, do: "property"

  def subscribe do
    EventBus.subscribe(topic())
  end
end
