defmodule AppCount.Support.Adapters.PubSubFake do
  @moduledoc """
  Prevents sending events in test environment
  """

  def subscribe(_pubsub_name, _topic) do
    :ok
  end

  def unsubscribe(_pubsub_name, _topic) do
    :ok
  end

  def broadcast(_pubsub_name, _topic, domain_event) do
    # This only works when the test is in the same process as the event bus
    send(self(), domain_event)
    :ok
  end
end
