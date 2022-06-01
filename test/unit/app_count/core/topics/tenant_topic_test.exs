defmodule AppCount.Core.TenantTopicTest do
  @moduledoc """
  For Tenant
  """
  use AppCount.DataCase
  alias AppCount.Core.TenantTopic
  alias AppCount.Core.DomainEvent

  describe "events" do
    setup do
      TenantTopic.subscribe()
    end

    test "created event" do
      # When
      _domain_event =
        TenantTopic.created(
          %{subject_name: AppCount.Tenants.Tenant, subject_id: 123},
          __MODULE__
        )

      # Then
      assert_receive %DomainEvent{
        topic: "tenants__tenants",
        name: "created",
        content: %{},
        subject_name: "AppCount.Tenants.Tenant",
        subject_id: 123,
        source: __MODULE__
      }
    end

    test "changed event" do
      # When
      _domain_event =
        TenantTopic.changed(
          %{
            subject_id: 123,
            subject_name: AppCount.Tenants.Tenant,
            changes: %{field_name: "new value"}
          },
          __MODULE__
        )

      # Then
      assert_receive %DomainEvent{
        topic: "tenants__tenants",
        name: "changed",
        content: %{changes: %{field_name: "new value"}},
        subject_name: "AppCount.Tenants.Tenant",
        subject_id: 123,
        source: __MODULE__
      }
    end

    test "deleted event" do
      # When
      _domain_event = TenantTopic.deleted(%{tenant_id: 123}, __MODULE__)

      # Then
      assert_receive %DomainEvent{
        topic: "tenants__tenants",
        name: "deleted",
        content: %{},
        subject_name: "AppCount.Tenants.Tenant",
        subject_id: 123,
        source: __MODULE__
      }
    end
  end
end
