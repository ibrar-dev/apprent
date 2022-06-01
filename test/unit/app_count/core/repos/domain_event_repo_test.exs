defmodule AppCount.Core.DomainEventRepoTest do
  use AppCount.DataCase
  alias AppCount.Core.DomainEventRepo
  alias AppCount.Core.DomainEvent

  setup do
    domain_event = %DomainEvent{
      topic: "topic",
      name: "subject_changed",
      content: "content",
      source: __MODULE__
    }

    ~M{domain_event}
  end

  test "store(event)" do
    original_count = DomainEventRepo.count()

    event = %DomainEvent{
      topic: "DomainEventRepoTest",
      name: "de-storage-test",
      content: %{test: "test"},
      source: __MODULE__
    }

    # When
    :ok = DomainEventRepo.store(event)
    # Then
    actual_count = DomainEventRepo.count()

    assert actual_count == original_count + 1
  end

  test "load topic with subset of topic name, should not find it", ~M{domain_event} do
    :ok = DomainEventRepo.store(domain_event)
    # When
    results = DomainEventRepo.load_topic("top")
    assert results == []
  end

  test "load topic", ~M{domain_event} do
    domain_event_off_topic = %{domain_event | topic: "blah"}
    :ok = DomainEventRepo.store(domain_event)
    :ok = DomainEventRepo.store(domain_event_off_topic)
    # When
    [result] = results = DomainEventRepo.load_topic("blah")
    # Then
    assert length(results) == 1
    assert result.topic == "blah"
  end

  test "load subject", ~M{domain_event} do
    subject_id = 123
    subject_name = AppCount.Leases.Lease

    domain_event_for_subject = %{
      domain_event
      | subject_id: subject_id,
        subject_name: subject_name
    }

    :ok = DomainEventRepo.store(domain_event)
    :ok = DomainEventRepo.store(domain_event_for_subject)
    # When
    results = DomainEventRepo.load_subject(subject_name, subject_id)
    assert length(results) == 1
  end

  test "load last subjects", ~M[domain_event] do
    sub_id = 123
    sub_name = AppCount.Properties.Property
    string_name = to_string(sub_name)

    domain_event_for_subject = %{
      domain_event
      | subject_id: sub_id,
        subject_name: sub_name
    }

    :ok = DomainEventRepo.store(domain_event_for_subject)
    :ok = DomainEventRepo.store(domain_event_for_subject)
    :ok = DomainEventRepo.store(domain_event)

    max_for_subject =
      Repo.all(
        from x in DomainEvent,
          where: x.subject_id == ^sub_id,
          where: x.subject_name == ^string_name,
          select: %{id: x.id}
      )
      |> Enum.map(fn x -> x.id end)
      |> Enum.max()

    # When
    results = DomainEventRepo.load_last_subjects(sub_name, [sub_id])
    assert length(results) == 1
    [event | _] = results
    assert event.id == max_for_subject
  end

  test "load last subjects with zero results" do
    sub_id = 123
    sub_name = AppCount.Properties.Property

    # When
    results = DomainEventRepo.load_last_subjects(sub_name, [sub_id])
    assert Enum.empty?(results)
  end
end
