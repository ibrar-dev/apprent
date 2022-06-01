defmodule AppCount.Properties.Server.PropertyServerTest do
  use AppCount.DataCase
  alias AppCount.Properties.Server.PropertyServer
  alias AppCount.Properties.Server.PropertyServerSupervisor
  alias AppCount.Core.DateRange
  alias AppCount.Core.DomainEvent
  alias AppCount.Properties.PropertyRepo
  alias AppCount.Core.ClientSchema

  setup do
    [builder, property] =
      PropBuilder.new(:create)
      |> PropBuilder.add_property()
      |> PropBuilder.add_property_setting()
      |> PropBuilder.get([:property])

    property_id = property.id
    ~M[builder, property_id]
  end

  test "start_link", ~M[property_id] do
    # When

    {:ok, pid} = PropertyServerSupervisor.start_property_server(property_id)

    # Then
    assert Process.alive?(pid)
    assert PropertyServer.alive?(property_id)

    # Cleanup
    PropertyServer.shut_down(property_id)
  end

  def load(property_id) do
    AppCount.Properties.Server.MiniProperty.load_property(
      property_id,
      AppCount.Properties.Server.MiniPropertyRepo
    )
  end

  describe "current_tenant_ids" do
    setup(~M[builder]) do
      [builder, property, tenant] =
        builder
        |> PropBuilder.add_unit()
        |> PropBuilder.add_tenant()
        |> PropBuilder.get([:property, :tenant])

      times =
        AppTime.new()
        |> AppTime.plus_to_date(:last_year, years: -1)
        |> AppTime.plus_to_date(:minus_6_months, days: -182)
        |> AppTime.plus_to_date(:yesterday, days: -1)
        |> AppTime.plus_to_date(:now, minutes: 0)
        |> AppTime.plus_to_date(:tommorow, days: 1)
        |> AppTime.plus_to_date(:plus_6_months, days: 182)
        |> AppTime.plus_to_date(:next_year, years: 1)
        |> AppTime.times()

      last_year = DateRange.new(times.last_year, times.yesterday)
      next_year = DateRange.new(times.tommorow, times.next_year)
      mid_year = DateRange.new(times.minus_6_months, times.plus_6_months)
      ~M[builder, property, tenant, times, last_year, next_year, mid_year]
    end

    test "(vacant) no lease", ~M[property] do
      state = load(property.id)

      {:reply, current_tenant_ids, _property} =
        PropertyServer.handle_call(:current_tenant_ids, self(), state)

      assert current_tenant_ids == []
    end

    test "one current lease", ~M[builder, property, tenant] do
      builder
      |> PropBuilder.add_lease()

      state = load(property.id)

      {:reply, current_tenant_ids, _property} =
        PropertyServer.handle_call(:current_tenant_ids, self(), state)

      assert current_tenant_ids == [tenant.id]
    end

    test "two tenants", ~M[builder, property, tenant] do
      builder
      |> PropBuilder.add_lease()

      tenant01 = tenant

      [_builder, tenant02] =
        builder
        |> PropBuilder.add_unit()
        |> PropBuilder.add_tenant()
        |> PropBuilder.add_lease()
        |> PropBuilder.get([:tenant])

      state = load(property.id)

      {:reply, current_tenant_ids, _property} =
        PropertyServer.handle_call(:current_tenant_ids, self(), state)

      assert Enum.member?(current_tenant_ids, tenant01.id)
      assert Enum.member?(current_tenant_ids, tenant02.id)
    end

    test "one expired lease", ~M[builder, property, last_year] do
      builder
      |> PropBuilder.add_lease_for(last_year)

      state = load(property.id)

      {:reply, current_tenant_ids, _property} =
        PropertyServer.handle_call(:current_tenant_ids, self(), state)

      assert current_tenant_ids == []
    end

    test "future lease, not a tenant", ~M[builder, property, next_year] do
      builder
      |> PropBuilder.add_lease_for(next_year)

      state = load(property.id)

      {:reply, current_tenant_ids, _property} =
        PropertyServer.handle_call(:current_tenant_ids, self(), state)

      assert current_tenant_ids == []
    end

    test "many leases", ~M[builder, property, tenant, last_year] do
      builder
      |> PropBuilder.add_lease_for(last_year)
      |> PropBuilder.add_lease()

      state = load(property.id)

      {:reply, current_tenant_ids, _property} =
        PropertyServer.handle_call(:current_tenant_ids, self(), state)

      assert current_tenant_ids == [tenant.id]
    end
  end

  describe "property, unit, tenent, standard lease" do
    setup(~M[builder]) do
      [builder, property, tenant, unit, lease] =
        builder
        |> PropBuilder.add_unit()
        |> PropBuilder.add_tenant()
        |> PropBuilder.add_lease()
        |> PropBuilder.get([:property, :tenant, :unit, :lease])

      state = load(property.id)

      ~M[builder, state, property, tenant, unit, lease]
    end

    test "unit_ids ", ~M[state, unit] do
      {:reply, unit_ids, _property} = PropertyServer.handle_call(:unit_ids, self(), state)
      assert unit_ids == [unit.id]
    end

    test "setting ", ~M[state] do
      {:reply, setting, _property} = PropertyServer.handle_call(:setting, self(), state)
      assert setting.__struct__ == AppCount.Properties.Setting
    end

    test "has_tenant? false", ~M[ state] do
      {:reply, result, _property} =
        PropertyServer.handle_call({:has_tenant?, 99999}, self(), state)

      refute result
    end

    test "has_tenant? true", ~M[state, tenant] do
      {:reply, result, _property} =
        PropertyServer.handle_call({:has_tenant?, tenant.id}, self(), state)

      assert result
    end
  end

  describe "unit_lease_tenant" do
    setup do
      [builder, property, unit, lease, tenant] =
        PropBuilder.new(:create)
        |> PropBuilder.add_property()
        |> PropBuilder.add_property_setting()
        |> PropBuilder.add_unit()
        |> PropBuilder.add_tenant()
        |> PropBuilder.add_lease()
        |> PropBuilder.get([:property, :unit, :lease, :tenant])

      state = load(property.id)

      ~M[builder, unit, lease, tenant, state]
    end

    test "handle_call(:unit_lease_tenant FOUND", ~M[  unit, lease, tenant, state] do
      # When
      {:reply, result, _state} =
        PropertyServer.handle_call({:unit_lease_tenant, tenant.id}, self(), state)

      # Then
      assert result == {:ok, {unit.id, lease.id, tenant.id}}
    end

    test "handle_call(:unit_lease_tenant NOT FOUND", ~M[ state] do
      # When
      {:reply, result, _state} =
        PropertyServer.handle_call({:unit_lease_tenant, 9999}, self(), state)

      # Then
      assert result == {:error, "Not Found unit_lease_tenant, tenant_id:9999"}
    end
  end

  describe "reload settings or property" do
    setup do
      [_builder, property] =
        PropBuilder.new(:create)
        |> PropBuilder.add_property()
        |> PropBuilder.add_property_setting()
        |> PropBuilder.get([:property])

      state = load(property.id)

      ~M[ property, state]
    end

    test "handle_info(DomainEvent{name: property_changed", ~M[ property, state] do
      new_property =
        PropertyRepo.update_property_settings(
          property,
          ClientSchema.new(
            "dasmen",
            %{tours: false}
          )
        )

      refute new_property.setting.tours

      event = %DomainEvent{name: "property_changed", content: %{property_id: property.id}}

      # When
      {:noreply, state} = PropertyServer.handle_info(event, state)

      # Then
      refute state.setting.tours
    end
  end
end
