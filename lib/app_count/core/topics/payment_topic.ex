defmodule AppCount.Core.PaymentTopic do
  @moduledoc """
  PaymentTopic maintains the event names
  and the name of the topic.
  """

  alias AppCount.Core.DomainEvent
  alias AppCount.Core.EventBus

  # -- API ---------
  def payment_confirmed(
        %AppCount.Core.ClientSchema{attrs: %{rent_saga_id: _rent_saga_id}} = content,
        source
      ) do
    %{event(:payment_confirmed) | content: content, source: source}
    |> EventBus.publish()
  end

  def payment_recorded(
        %{rent_payment_id: _rent_payment_id, account_id: _account_id, line_items: _line_items} =
          content,
        source
      ) do
    %{event(:payment_recorded) | content: content, source: source}
    |> EventBus.publish()
  end

  # --- Event Names ---

  def name(:payment_confirmed), do: "payment_confirmed"
  def name(:payment_recorded), do: "payment_recorded"

  # --- Event Builders ---
  def event(:payment_confirmed),
    do: %DomainEvent{name: name(:payment_confirmed), topic: topic()}

  def event(:payment_recorded),
    do: %DomainEvent{name: name(:payment_recorded), topic: topic()}

  #  --- General ---
  def topic, do: "payments"

  def subscribe do
    EventBus.subscribe(topic())
  end
end
