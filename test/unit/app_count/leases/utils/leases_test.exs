defmodule AppCount.Leases.Utils.LeasesTest do
  use AppCount.DataCase
  alias AppCount.Leases.Utils.Leases
  alias AppCount.Core.LeaseTopic
  alias AppCount.Core.DomainEvent
  alias AppCount.Core.ClientSchema

  defmodule TenantRepoParrot do
    use TestParrot
    parrot(:repo, :get, nil)
  end

  describe "publish_lease_created_event" do
    test "one" do
      LeaseTopic.subscribe()

      tenant_id = 111
      lease_id = 222

      TenantRepoParrot.say_get(%AppCount.Tenants.Tenant{id: tenant_id})

      # When
      _result = Leases.publish_lease_created_event(lease_id, tenant_id, TenantRepoParrot)

      # Then
      # Call to TenantRepo
      assert_receive {:get, ^tenant_id}

      # publish event
      assert_receive %AppCount.Core.DomainEvent{
        content: %{tenant_id: ^tenant_id},
        name: "created",
        source: AppCount.Leases.Utils.Leases,
        subject_id: ^lease_id,
        subject_name: "AppCount.Leases.Lease",
        topic: "leases__leases"
      }
    end
  end

  describe "create_lease()" do
    setup do
      LeaseTopic.subscribe()
    end

    test "fails" do
      params = %{}
      # When
      result = Leases.create_lease(ClientSchema.new("dasmen", params))

      assert {:error, :lease, changeset, %{}} = result

      refute_valid(changeset)
      assert "can't be blank" in errors_on(changeset).start_date
      assert "can't be blank" in errors_on(changeset).end_date
      assert "can't be blank" in errors_on(changeset).unit_id

      refute_receive %DomainEvent{}
    end

    test "succeeds" do
      dates =
        AppTime.new()
        |> AppTime.plus_to_date(:yesterday, days: -1)
        |> AppTime.plus_to_date(:tomorrow, days: 1)
        |> AppTime.times()

      [_builder, unit, tenant] =
        PropBuilder.new()
        |> PropBuilder.add_property()
        |> PropBuilder.add_unit()
        |> PropBuilder.add_rent_application()
        |> PropBuilder.add_tenant()
        |> PropBuilder.add_person()
        |> PropBuilder.get([:unit, :tenant])

      params = %{
        tenant_id: tenant.id,
        start_date: dates.yesterday,
        end_date: dates.tomorrow,
        unit_id: unit.id
      }

      # When
      result = Leases.create_lease(ClientSchema.new("dasmen", params))

      # Then
      assert {:ok, %{lease: lease}} = result
      lease_id = lease.id
      tenant_id = tenant.id

      assert_receive %AppCount.Core.DomainEvent{name: "property_created"}

      assert_receive %DomainEvent{
        topic: "leases__leases",
        name: "created",
        content: %{tenant_id: ^tenant_id},
        subject_name: "AppCount.Leases.Lease",
        subject_id: ^lease_id,
        source: AppCount.Leases.Utils.Leases
      }
    end
  end
end
