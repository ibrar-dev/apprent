defmodule AppCount.Core.RentApplicationTopic do
  @moduledoc """
  RentApplicationTopic maintains the event names
  and the name of the topic.
  The API section shows what it can do
  """

  alias AppCount.Core.DomainEvent
  alias AppCount.Core.EventBus

  # -- API ---------
  def created(rent_application_id, %{line_items: _, account_id: _} = content, source) do
    %{
      event(:created)
      | content: content,
        subject_id: rent_application_id,
        subject_name: "AppCount.RentApply.RentApplication",
        source: source
    }
    |> EventBus.publish()
  end

  # --- Event Names ---

  def name(:created), do: "created"

  # --- Event Builders ---
  def event(:created),
    do: %DomainEvent{name: name(:created), topic: topic()}

  #  --- General ---
  def topic, do: "rent_apply__rent_applications"

  def subscribe do
    EventBus.subscribe(topic())
  end
end
