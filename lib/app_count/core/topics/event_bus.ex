defmodule AppCount.Core.EventBus do
  alias AppCount.Core.DomainEvent
  @pubsub_name AppCount.PubSub

  @pub_sub_adapter AppCount.adapters(:pub_sub, Phoenix.PubSub)

  def subscribe(topic) do
    :ok = @pub_sub_adapter.subscribe(@pubsub_name, topic)
  end

  def unsubscribe(topic) do
    :ok = @pub_sub_adapter.unsubscribe(@pubsub_name, topic)
  end

  def publish(%DomainEvent{topic: topic} = domain_event) do
    :ok = @pub_sub_adapter.broadcast(@pubsub_name, topic, domain_event)
    domain_event
  end
end
