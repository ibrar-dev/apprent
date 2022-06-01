defmodule AppCount.Core.OrderTopic do
  # OrderTopic maintains the event nams
  # and the name of the topic.
  # The API section shows what it can do

  alias AppCount.Core.DomainEvent
  alias AppCount.Core.EventBus
  alias AppCount.Core.OrderTopic.Info

  # -- API ---------
  def order_created(%Info{} = info, source) do
    %{event(:order_created) | content: info, source: source}
    |> EventBus.publish()
  end

  def order_assigned(%Info{} = info, source) do
    %{event(:order_assigned) | content: info, source: source}
    |> EventBus.publish()
  end

  def tech_dispatched(%Info{} = info, source) do
    %{event(:tech_dispatched) | content: info, source: source}
    |> EventBus.publish()
  end

  def order_completed(%Info{} = info, source) do
    %{event(:order_completed) | content: info, source: source}
    |> EventBus.publish()
  end

  # --- Event Names ---

  def name(:order_created), do: "order_created"
  def name(:order_assigned), do: "order_assigned"
  def name(:tech_dispatched), do: "tech_dispatched"
  def name(:order_completed), do: "order_completed"

  # --- Event Builders ---
  def event(:order_created),
    do: %DomainEvent{name: name(:order_created), topic: topic()}

  def event(:order_assigned),
    do: %DomainEvent{name: name(:order_assigned), topic: topic()}

  def event(:tech_dispatched),
    do: %DomainEvent{name: name(:tech_dispatched), topic: topic()}

  def event(:order_completed),
    do: %DomainEvent{name: name(:order_completed), topic: topic()}

  #  --- General ---
  def topic, do: "order"

  def subscribe do
    EventBus.subscribe(topic())
  end
end
