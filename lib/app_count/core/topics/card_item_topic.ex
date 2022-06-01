defmodule AppCount.Core.CardItemTopic do
  alias AppCount.Core.DomainEvent
  alias AppCount.Core.EventBus
  alias AppCount.Core.CardItemTopic.Content

  @subject_name AppCount.Maintenance.Card

  # -- API ---------
  def card_item_completed(%Content{card_id: card_id} = content, source) do
    %{
      event(:card_item_completed)
      | content: content,
        source: source,
        subject_id: card_id,
        subject_name: @subject_name
    }
    |> EventBus.publish()
  end

  def card_item_reverted(%Content{card_id: card_id} = content, source) do
    %{
      event(:card_item_reverted)
      | content: content,
        source: source,
        subject_id: card_id,
        subject_name: @subject_name
    }
    |> EventBus.publish()
  end

  def card_item_created(%Content{card_id: card_id} = content, source) do
    %{
      event(:card_item_created)
      | content: content,
        source: source,
        subject_id: card_id,
        subject_name: @subject_name
    }
    |> EventBus.publish()
  end

  def card_item_updated(%Content{card_id: card_id} = content, source) do
    %{
      event(:card_item_updated)
      | content: content,
        source: source,
        subject_id: card_id,
        subject_name: @subject_name
    }
    |> EventBus.publish()
  end

  def card_item_confirmed(%Content{card_id: card_id} = content, source) do
    %{
      event(:card_item_confirmed)
      | content: content,
        source: source,
        subject_id: card_id,
        subject_name: @subject_name
    }
    |> EventBus.publish()
  end

  def card_item_deleted(%Content{card_id: card_id} = content, source) do
    %{
      event(:card_item_deleted)
      | content: content,
        source: source,
        subject_id: card_id,
        subject_name: @subject_name
    }
    |> EventBus.publish()
  end

  # --- Event Names ---
  def name(:card_item_completed), do: "card_item_completed"
  def name(:card_item_reverted), do: "card_item_reverted"
  def name(:card_item_created), do: "card_item_created"
  def name(:card_item_updated), do: "card_item_updated"
  def name(:card_item_confirmed), do: "card_item_confirmed"
  def name(:card_item_deleted), do: "card_item_deleted"

  # --- Event Builders ---
  def event(:card_item_completed),
    do: %DomainEvent{name: name(:card_item_completed), topic: topic()}

  def event(:card_item_reverted),
    do: %DomainEvent{name: name(:card_item_reverted), topic: topic()}

  def event(:card_item_created),
    do: %DomainEvent{name: name(:card_item_created), topic: topic()}

  def event(:card_item_updated),
    do: %DomainEvent{name: name(:card_item_updated), topic: topic()}

  def event(:card_item_confirmed),
    do: %DomainEvent{name: name(:card_item_confirmed), topic: topic()}

  def event(:card_item_deleted),
    do: %DomainEvent{name: name(:card_item_deleted), topic: topic()}

  #  --- General ---
  def topic, do: "card_item"

  def subscribe do
    EventBus.subscribe(topic())
  end
end
