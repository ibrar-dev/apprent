defmodule AppCount.Core.DomainEventTest do
  use AppCount.DataCase
  alias AppCount.Core.DomainEvent

  setup do
    domain_event = %DomainEvent{
      topic: "topic",
      name: "name",
      content: "content",
      source: "AppCount.Core.DomainEventTest"
    }

    ~M{domain_event}
  end

  test "create / insert", ~M{domain_event} do
    result =
      domain_event
      |> DomainEvent.createset()
      |> Repo.insert()

    assert {:ok, _} = result
  end

  test "retrieve", ~M{domain_event} do
    domain_event
    |> Repo.insert!()

    [retrieved_domain_event] = Repo.all(DomainEvent)

    assert retrieved_domain_event.inserted_at != nil
    assert retrieved_domain_event.id != nil
  end

  test "invalid create", ~M{domain_event} do
    change_set =
      %{domain_event | name: nil}
      |> DomainEvent.createset()

    assert change_set.errors == [name: {"can't be blank", [validation: :required]}]
  end
end
