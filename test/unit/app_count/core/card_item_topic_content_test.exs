defmodule AppCount.Core.CardTopicItemContentTest do
  use AppCount.DataCase
  alias AppCount.Maintenance.CardItem
  alias AppCount.Core.CardItemTopic.Content

  test "valid data" do
    content = Content.new(%CardItem{id: 654, card_id: 1234})

    assert content.card_item_id == 654
    assert content.card_id == 1234
  end
end
