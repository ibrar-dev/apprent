defmodule AppCount.Core.CardTopic do
  alias AppCount.Core.DomainEvent
  alias AppCount.Core.EventBus
  alias AppCount.Core.CardTopic.Content

  @subject_name AppCount.Maintenance.Card

  # -- API ---------
  def card_created(%Content{card_id: card_id} = content, source) do
    %{
      event(:card_created)
      | content: content,
        source: source,
        subject_id: card_id,
        subject_name: @subject_name
    }
    |> EventBus.publish()
  end

  def card_updated(%Content{card_id: card_id} = content, source) do
    %{
      event(:card_updated)
      | content: content,
        source: source,
        subject_id: card_id,
        subject_name: @subject_name
    }
    |> EventBus.publish()
  end

  # --- Event Names ---
  def name(:card_created), do: "card_created"
  def name(:card_updated), do: "card_updated"

  # --- Event Builders ---
  def event(:card_created),
    do: %DomainEvent{name: name(:card_created), topic: topic()}

  def event(:card_updated),
    do: %DomainEvent{name: name(:card_updated), topic: topic()}

  #  --- General ---
  def topic, do: "card"

  def subscribe do
    EventBus.subscribe(topic())
  end
end
