defmodule AppCount.Core.CardItemTopicTest do
  use AppCount.DataCase
  alias AppCount.Core.CardItemTopic
  alias AppCount.Core.CardItemTopic.Content
  alias AppCount.Core.DomainEvent

  describe "events" do
    setup do
      CardItemTopic.subscribe()
      content = %Content{card_item_id: 765, card_id: 1234}
      subject_name = AppCount.Maintenance.Card

      ~M[content, subject_name]
    end

    test "card_item_completed_event", ~M[content, subject_name] do
      CardItemTopic.subscribe()
      # When
      _domain = CardItemTopic.card_item_completed(content, __MODULE__)

      # Then

      assert_receive %DomainEvent{
        topic: "card_item",
        name: "card_item_completed",
        content: %{},
        source: __MODULE__,
        subject_id: 1234,
        subject_name: ^subject_name
      }
    end

    test "card_item_revert_event", ~M[content,  subject_name] do
      CardItemTopic.subscribe()
      # When
      _domain = CardItemTopic.card_item_reverted(content, __MODULE__)

      # Then
      assert_receive %DomainEvent{
        topic: "card_item",
        name: "card_item_reverted",
        content: %{},
        source: __MODULE__,
        subject_id: 1234,
        subject_name: ^subject_name
      }
    end

    test "card_item_created_event", ~M[content, subject_name] do
      CardItemTopic.subscribe()
      # When
      _domain_event = CardItemTopic.card_item_created(content, __MODULE__)

      # Then

      assert_receive %DomainEvent{
        topic: "card_item",
        name: "card_item_created",
        content: %{},
        source: __MODULE__,
        subject_id: 1234,
        subject_name: ^subject_name
      }
    end

    test "card_item_updated_event", ~M[content, subject_name] do
      CardItemTopic.subscribe()
      # When
      _domain = CardItemTopic.card_item_updated(content, __MODULE__)

      # Then
      assert_receive %DomainEvent{
        topic: "card_item",
        name: "card_item_updated",
        content: %{},
        source: __MODULE__,
        subject_id: 1234,
        subject_name: ^subject_name
      }
    end

    test "card_item_confirmed_event", ~M[content, subject_name] do
      CardItemTopic.subscribe()
      # When
      _domain = CardItemTopic.card_item_confirmed(content, __MODULE__)

      # Then
      assert_receive %DomainEvent{
        topic: "card_item",
        name: "card_item_confirmed",
        content: %{},
        source: __MODULE__,
        subject_id: 1234,
        subject_name: ^subject_name
      }
    end

    test "card_item_deleted_event", ~M[content,  subject_name] do
      CardItemTopic.subscribe()
      # When
      _domain = CardItemTopic.card_item_deleted(content, __MODULE__)

      # Then

      assert_receive %DomainEvent{
        topic: "card_item",
        name: "card_item_deleted",
        content: %{},
        source: __MODULE__,
        subject_id: 1234,
        subject_name: ^subject_name
      }
    end
  end
end
