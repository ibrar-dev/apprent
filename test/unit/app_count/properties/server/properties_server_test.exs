defmodule AppCount.Properties.Server.PropertiesServerTest do
  @moduledoc false
  use AppCount.DataCase
  alias AppCount.Properties.Server.PropertyServer
  alias AppCount.Properties.Server.PropertiesServer
  alias AppCount.Properties.Server.PropertyServerSupervisor
  alias AppCount.Core.DomainEvent

  defmodule PropertyServerSupervisorParrot do
    use TestParrot
    parrot(:supervisor, :start_property_server, 111)
  end

  defmodule PropertyServerParrot do
    use TestParrot
    parrot(:property_server, :load, 345)
  end

  test "start_link", ~M[test] do
    {:ok, pid} = PropertiesServer.start_link(name: test)

    # Then
    assert Process.alive?(pid)
    PropertiesServer.shut_down(test)
  end

  describe "property_unit_lease_tenant" do
    setup do
      [builder, property, unit, lease, tenant] =
        PropBuilder.new(:create)
        |> PropBuilder.add_property()
        |> PropBuilder.add_property_setting()
        |> PropBuilder.add_unit()
        |> PropBuilder.add_tenant()
        |> PropBuilder.add_lease()
        |> PropBuilder.get([:property, :unit, :lease, :tenant])

      ~M[builder, property, unit, lease, tenant]
    end

    test "handle_call FOUND", ~M[ property, unit, lease, tenant] do
      {:ok, _pid} = PropertyServerSupervisor.start_property_server(property.id)
      state = %PropertiesServer{active_property_ids: [property.id]}

      # When
      {:reply, result, state} =
        PropertiesServer.handle_call({:property_unit_lease_tenant, tenant.id}, self(), state)

      assert result == [{property.id, unit.id, lease.id, tenant.id}]
      assert state == %PropertiesServer{active_property_ids: [property.id]}

      # Cleanup
      PropertyServer.shut_down(property.id)
    end

    test "handle_call NOT FOUND", ~M[ property] do
      {:ok, _pid} = PropertyServerSupervisor.start_property_server(property.id)
      state = %PropertiesServer{active_property_ids: [property.id]}

      # When
      {:reply, result, state} =
        PropertiesServer.handle_call({:property_unit_lease_tenant, 999}, self(), state)

      assert result == []
      assert state == %PropertiesServer{active_property_ids: [property.id]}

      # Cleanup
      PropertyServer.shut_down(property.id)
    end

    test "handle_info property_created", ~M[ property] do
      property_id = property.id
      domain_event = %DomainEvent{name: "property_created", content: %{property_id: property_id}}

      state = %PropertiesServer{
        active_property_ids: [property_id],
        deps: %{supervisor: PropertyServerSupervisorParrot}
      }

      # When
      {:noreply, _state} = PropertiesServer.handle_info(domain_event, state)

      assert_received {:start_property_server, ^property_id}
    end

    test "handle_info property_changed", ~M[ property] do
      property_id = property.id
      domain_event = %DomainEvent{name: "property_changed", content: %{property_id: property_id}}

      state = %PropertiesServer{
        active_property_ids: [property_id],
        deps: %{property_server: PropertyServerParrot}
      }

      # When
      {:noreply, _state} = PropertiesServer.handle_info(domain_event, state)

      assert_received {:load, ^property_id}
    end
  end
end
