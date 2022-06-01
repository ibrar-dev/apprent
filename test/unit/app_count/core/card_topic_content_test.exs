defmodule AppCount.Core.CardTopicContentTest do
  use AppCount.DataCase
  alias AppCount.Maintenance.Card
  alias AppCount.Core.CardTopic.Content

  test "valid data" do
    content = Content.new(%Card{id: 1234})

    assert content.card_id == 1234
  end
end
