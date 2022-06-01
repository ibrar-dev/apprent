defmodule AppCount.Core.FinanceAccountTopicTest do
  @moduledoc """
  For Financial Accounts
  """
  use AppCount.DataCase
  alias AppCount.Core.FinanceAccountTopic
  alias AppCount.Core.DomainEvent

  describe "events" do
    setup do
      FinanceAccountTopic.subscribe()
      meta = %{subject_name: "schema_name", subject_id: 999}
      ~M[meta]
    end

    test "created event", ~M[meta] do
      # When
      _domain_event = FinanceAccountTopic.created(meta, __MODULE__)

      # Then
      assert_receive %DomainEvent{
        topic: "finance__accounts",
        name: "created",
        content: %{},
        source: __MODULE__
      }
    end

    test "changed event", ~M[meta] do
      # When
      _domain_event = FinanceAccountTopic.changed(meta, __MODULE__)

      # Then
      assert_receive %DomainEvent{
        topic: "finance__accounts",
        name: "changed",
        content: %{},
        source: __MODULE__
      }
    end

    test "deleted event", ~M[ meta] do
      # When
      _domain_event = FinanceAccountTopic.deleted(meta, __MODULE__)

      # Then
      assert_receive %DomainEvent{
        topic: "finance__accounts",
        name: "deleted",
        content: %{},
        source: __MODULE__
      }
    end
  end
end
