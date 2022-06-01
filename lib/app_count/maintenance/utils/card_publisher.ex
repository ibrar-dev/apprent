defmodule AppCount.Maintenance.Utils.CardPublisher do
  alias AppCount.Core.CardTopic
  alias AppCount.Core.CardTopic.Content
  alias AppCount.Maintenance.CardRepo
  require Logger

  # Created
  def publish_card_created_event(card_id) do
    card_id
    |> load_info()
    |> CardTopic.card_created(__MODULE__)
  end

  # Updated
  def publish_card_updated_event(card_id) do
    load_info(card_id)
    |> CardTopic.card_updated(__MODULE__)
  end

  # --- get from DB ---
  #
  def load_info(card_id) do
    card = CardRepo.get(card_id)
    Content.new(card)
  end
end
