defmodule AppCount.Maintenance.Utils.CardPublisherTest do
  use AppCount.DataCase
  alias AppCount.Maintenance.Utils.CardPublisher
  alias AppCount.Core.CardTopic

  setup do
    card =
      PropBuilder.new(:create)
      |> PropBuilder.add_property()
      |> PropBuilder.add_unit()
      |> PropBuilder.add_card()
      |> PropBuilder.get_requirement(:card)

    CardTopic.subscribe()

    ~M[card]
  end

  describe "publish_card_created_event" do
    test "card_created", ~M[card] do
      CardPublisher.publish_card_created_event(card.id)

      assert_receive %{topic: "card", name: "card_created"}
    end
  end

  describe "publish_card_updated_event" do
    test "card_updated", ~M[card] do
      CardPublisher.publish_card_updated_event(card.id)

      assert_receive %{topic: "card", name: "card_updated"}
    end
  end
end
