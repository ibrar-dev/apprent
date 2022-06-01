defmodule AppCount.Core.CardItemTopic.Content do
  alias __MODULE__
  alias AppCount.Maintenance.CardItem

  @required [
    :card_item_id,
    :card_id
  ]

  @fields @required

  @enforce_keys @required
  defstruct @fields

  def new(%CardItem{id: id, card_id: card_id}) do
    %Content{
      card_item_id: id,
      card_id: card_id
    }
  end
end
