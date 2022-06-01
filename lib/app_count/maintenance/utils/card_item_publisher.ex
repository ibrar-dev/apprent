defmodule AppCount.Maintenance.Utils.CardItemPublisher do
  alias AppCount.Core.CardItemTopic
  alias AppCount.Core.CardItemTopic.Content
  alias AppCount.Maintenance.CardItemRepo
  require Logger

  # Created
  def publish_card_item_created_event(card_item_id) do
    card_item_id
    |> load_info()
    |> CardItemTopic.card_item_created(__MODULE__)
  end

  # Updated
  def publish_card_item_updated_event(card_item_id) do
    card_item_id
    |> load_info()
    |> CardItemTopic.card_item_updated(__MODULE__)
  end

  # Completed
  def publish_card_item_completed_event(card_item_id) do
    card_item_id
    |> load_info()
    |> CardItemTopic.card_item_completed(__MODULE__)
  end

  # Reverted
  def publish_card_item_reverted_event(card_item_id) do
    card_item_id
    |> load_info()
    |> CardItemTopic.card_item_reverted(__MODULE__)
  end

  # Confirmed
  def publish_card_item_confirmed_event(card_item_id) do
    card_item_id
    |> load_info()
    |> CardItemTopic.card_item_confirmed(__MODULE__)
  end

  # Deleted
  def publish_card_item_deleted_event(card_item_id) do
    card_item_id
    |> load_info()
    |> CardItemTopic.card_item_deleted(__MODULE__)
  end

  # --- get from DB ---
  #
  def load_info(card_item_id) do
    card_item = CardItemRepo.get(card_item_id)
    Content.new(card_item)
  end
end
