defmodule AppCount.Core.SmsTopic do
  alias AppCount.Core.DomainEvent
  alias AppCount.Core.EventBus

  @behaviour AppCount.Core.SmsTopicBehaviour
  def topic, do: "sms"

  # -- API ---------
  # For when the text will be sent from the default phone number.
  @impl AppCount.Core.SmsTopicBehaviour
  def sms_requested(phone_to, message, source) do
    content = %{phone_to: phone_to, message: message, phone_from: nil}

    %{event(:sms_requested) | content: content, source: source}
    |> EventBus.publish()
  end

  @impl AppCount.Core.SmsTopicBehaviour
  def message_received({phone_from, phone_to, params}, source) do
    content = %{phone_from: phone_from, phone_to: phone_to, params: params}

    %{event(:message_received) | content: content, source: source}
    |> EventBus.publish()
  end

  # For when the text will be sent from a specific phone number.
  @impl AppCount.Core.SmsTopicBehaviour
  def message_sent({phone_from, phone_to, message}, source) do
    content = %{phone_from: phone_from, phone_to: phone_to, message: message}

    %{event(:sms_requested) | content: content, source: source}
    |> EventBus.publish()
  end

  @impl AppCount.Core.SmsTopicBehaviour
  def invalid_phone_number(%{phone: phone}, source) do
    content = %{phone: phone}

    %{event(:invalid_phone_number) | content: content, source: source}
    |> EventBus.publish()
  end

  # --- Event Names ---
  def name(:sms_requested), do: "sms_requested"
  def name(:message_received), do: "message_received"
  def name(:message_sent), do: "message_sent"
  def name(:invalid_phone_number), do: "invalid_phone_number"

  def event(:sms_requested),
    do: %DomainEvent{name: name(:sms_requested), topic: topic(), subject_name: UUID.uuid4()}

  def event(:message_received),
    do: %DomainEvent{name: name(:message_received), topic: topic(), subject_name: UUID.uuid4()}

  def event(:message_sent),
    do: %DomainEvent{name: name(:message_sent), topic: topic(), subject_name: UUID.uuid4()}

  def event(:invalid_phone_number),
    do: %DomainEvent{
      name: name(:invalid_phone_number),
      topic: topic(),
      subject_name: UUID.uuid4()
    }

  def subscribe do
    EventBus.subscribe(topic())
  end
end
