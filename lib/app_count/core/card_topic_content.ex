defmodule AppCount.Core.CardTopic.Content do
  alias __MODULE__
  alias AppCount.Maintenance.Card

  @required [
    :card_id
  ]

  @fields @required
  @derive {Jason.Encoder, only: @fields}

  @enforce_keys @required
  defstruct @fields

  def new(%Card{id: id}) do
    %Content{card_id: id}
  end
end
