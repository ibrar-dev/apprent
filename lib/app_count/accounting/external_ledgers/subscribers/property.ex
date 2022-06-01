defmodule AppCount.Accounting.ExternalLedgers.Subscribers.Property do
  # alias AppCount.Core.EventBus
  # alias AppCount.Core.DomainEvent
  # use GenServer

  def property_created(_event) do
    # IO.inspect("PROPERTY CREATED")
  end

  def property_updated(_event) do
    # IO.inspect("PROPERTY UPDATED")
  end

  def property_deleted(_event) do
    # IO.inspect("PROPERTY DELETED")
  end
end
