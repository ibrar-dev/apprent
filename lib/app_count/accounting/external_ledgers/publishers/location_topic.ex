defmodule AppCount.Accounting.ExternalLedgers.Publishers.PropertyTopic do
  alias AppCount.Core.DomainEvent
  alias AppCount.Core.EventBus

  # content can be string, tuple, map, list

  def name(:create), do: "property_created"
  def name(:update), do: "property_updated"
  def name(:delete), do: "property_deleted"

  def create_location(property_id, admin_id, source) do
    %DomainEvent{
      topic: topic(),
      name: name(:create),
      content: %{
        property_id: property_id,
        admin_id: admin_id
      },
      source: source
    }
    |> EventBus.publish()
  end

  def update_location(params, admin_id, source) do
    %DomainEvent{
      topic: topic(),
      name: name(:update),
      content: Map.put(params, :admin_id, admin_id),
      source: source
    }
    |> EventBus.publish()
  end

  def delete_location(property_id, admin_id, source) do
    %DomainEvent{
      topic: topic(),
      name: name(:delete),
      content: %{
        property_id: property_id,
        admin_id: admin_id
      },
      source: source
    }
    |> EventBus.publish()
  end

  #  --- General ---
  def topic, do: "external_ledger"

  def subscribe do
    EventBus.subscribe(topic())
  end
end
