defmodule AppCount.Core.InvoiceSagaTopic do
  @moduledoc """
  InvoiceSagaTopic maintains the event names
  and the name of the topic.
  The API section shows what it can do
  """

  alias AppCount.Core.DomainEvent
  alias AppCount.Core.EventBus

  # -- API ---------
  def completed({subject_name, subject_id}, content, source) do
    %{
      event(:completed)
      | content: content,
        subject_id: subject_id,
        subject_name: subject_name,
        source: source
    }
    |> EventBus.publish()
  end

  # --- Event Builders ---
  def event(:completed),
    do: %DomainEvent{name: "completed", topic: topic()}

  #  --- General ---
  def topic, do: "invoice_saga"

  def subscribe do
    EventBus.subscribe(topic())
  end
end
