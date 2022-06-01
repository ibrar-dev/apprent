defmodule AppCount.Core.LeaseTopicTest do
  @moduledoc """
  For Lease
  """
  use AppCount.DataCase
  alias AppCount.Core.LeaseTopic
  alias AppCount.Core.DomainEvent

  describe "events" do
    setup do
      LeaseTopic.subscribe()
    end

    test "created event" do
      # When
      _domain_event = LeaseTopic.created(%{lease_id: 999, tenant_id: 123}, __MODULE__)

      # Then
      assert_receive %DomainEvent{
        topic: "leases__leases",
        name: "created",
        content: %{tenant_id: 123},
        subject_name: "AppCount.Leases.Lease",
        subject_id: 999,
        source: __MODULE__
      }
    end
  end
end
