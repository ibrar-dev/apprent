defmodule AppCount.Maintenance.Utils.CardItemPublisherTest do
  use AppCount.DataCase
  alias AppCount.Maintenance.Utils.CardItemPublisher
  alias AppCount.Core.CardItemTopic

  setup do
    card_item =
      PropBuilder.new(:create)
      |> PropBuilder.add_property()
      |> PropBuilder.add_unit()
      |> PropBuilder.add_card()
      |> PropBuilder.add_card_item()
      |> PropBuilder.get_requirement(:card_item)

    CardItemTopic.subscribe()

    ~M[card_item]
  end

  describe "publish_card_item_created_event" do
    test "card_item_created", ~M[card_item] do
      CardItemPublisher.publish_card_item_created_event(card_item.id)

      assert_receive %{topic: "card_item", name: "card_item_created"}
    end
  end

  describe "publish_card_item_updated_event" do
    test "card_item_updated", ~M[card_item] do
      CardItemPublisher.publish_card_item_updated_event(card_item.id)

      assert_receive %{topic: "card_item", name: "card_item_updated"}
    end
  end

  describe "publish_card_item_completed_event" do
    test "card_item_completed", ~M[card_item] do
      CardItemPublisher.publish_card_item_completed_event(card_item.id)

      assert_receive %{topic: "card_item", name: "card_item_completed"}
    end
  end

  describe "publish_card_item_reverted_event" do
    test "card_item_completed", ~M[card_item] do
      CardItemPublisher.publish_card_item_reverted_event(card_item.id)

      assert_receive %{topic: "card_item", name: "card_item_reverted"}
    end
  end

  describe "publish_card_item_confirmed_event" do
    test "card_item_confirmed", ~M[card_item] do
      CardItemPublisher.publish_card_item_confirmed_event(card_item.id)

      assert_receive %{topic: "card_item", name: "card_item_confirmed"}
    end
  end

  describe "publish_card_item_deleted_event" do
    test "card_item_deleted", ~M[card_item] do
      CardItemPublisher.publish_card_item_deleted_event(card_item.id)

      assert_receive %{topic: "card_item", name: "card_item_deleted"}
    end
  end
end
