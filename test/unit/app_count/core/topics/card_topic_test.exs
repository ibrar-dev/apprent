defmodule AppCount.Core.CardTopicTest do
  use AppCount.DataCase
  alias AppCount.Core.CardTopic
  alias AppCount.Core.CardTopic.Content
  alias AppCount.Core.DomainEvent

  describe "events" do
    setup do
      CardTopic.subscribe()
      content = %Content{card_id: 1234}
      subject_name = AppCount.Maintenance.Card

      ~M[content,  subject_name]
    end

    test "card_created_event", ~M[content, subject_name] do
      CardTopic.subscribe()
      # When
      _domain_event = CardTopic.card_created(content, __MODULE__)

      # Then
      assert_receive %DomainEvent{
        topic: "card",
        name: "card_created",
        content: %{},
        source: __MODULE__,
        subject_id: 1234,
        subject_name: ^subject_name
      }
    end

    test "card_updated_event", ~M[content, subject_name] do
      CardTopic.subscribe()
      # When
      _domain_event = CardTopic.card_updated(content, __MODULE__)

      # Then
      assert_receive %DomainEvent{
        topic: "card",
        name: "card_updated",
        content: %{},
        source: __MODULE__,
        subject_id: 1234,
        subject_name: ^subject_name
      }
    end
  end
end
