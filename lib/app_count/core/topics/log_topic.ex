defmodule AppCount.Core.LogTopic do
  alias AppCount.Core.DomainEvent
  alias AppCount.Core.DomainEventRepo
  alias AppCount.Core.EventBus

  def topic, do: "log"

  # --- Event Names ---
  def name(:item_created), do: "item_created"

  def subscribe do
    EventBus.subscribe(topic())
  end

  def log!(content, source) do
    %DomainEvent{topic: topic(), name: name(:item_created), content: content, source: source}
    |> EventBus.publish()
  end

  def load_log do
    DomainEventRepo.load_topic(topic())
  end
end
