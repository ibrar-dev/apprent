defmodule AppCount.Core.SmsTopicTest do
  use AppCount.DataCase
  alias AppCount.Core.SmsTopic
  alias AppCount.Core.DomainEvent

  describe "subscribed" do
    setup do
      SmsTopic.subscribe()
      :ok
    end

    test "sms_requested broadcasts event" do
      # When
      _domain_event = SmsTopic.sms_requested("+15135551234", "message", __MODULE__)
      # Then
      assert_receive %DomainEvent{
        topic: "sms",
        name: "sms_requested",
        content: %{message: "message", phone_to: "+15135551234"}
      }
    end

    test "message_received broadcasts event" do
      # When
      _domain_event =
        SmsTopic.message_received(
          {"+15135551234", "+15005555555", %{body: "message"}},
          __MODULE__
        )

      # Then
      assert_receive %DomainEvent{
        topic: "sms",
        name: "message_received",
        content: %{params: %{body: "message"}, phone_to: "+15005555555"}
      }
    end

    test "message_sent broadcasts correct event" do
      # When
      _domain_event =
        SmsTopic.message_sent({"+15135551234", "+15005555555", "message"}, __MODULE__)

      # Then
      assert_receive %DomainEvent{
        topic: "sms",
        name: "sms_requested",
        content: %{message: "message", phone_to: "+15005555555", phone_from: "+15135551234"}
      }
    end

    test "invalid_phone_number" do
      # When
      _domain_event = SmsTopic.invalid_phone_number(%{phone: "+15135551234"}, __MODULE__)

      # Then
      assert_receive %DomainEvent{
        topic: "sms",
        name: "invalid_phone_number",
        content: %{phone: "+15135551234"}
      }
    end
  end
end
