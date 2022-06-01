defmodule AppCount.Core.TenantObserverTest do
  @moduledoc false
  use AppCount.DataCase
  alias AppCount.Core.TenantObserver
  alias AppCount.Core.DomainEvent
  alias AppCount.Core.TenantObserver.State
  import ShorterMaps

  defmodule TenantObserverStateParrot do
    @moduledoc false
    use TestParrot
    parrot(:observer, :payment_status_changed_to_cash, :ok)
    parrot(:observer, :autopay_activated_notification, :ok)
    parrot(:observer, :autopay_deactivated_notification, :ok)
    parrot(:observer, :update_invalid_phone_numbers, :ok)
    parrot(:observer, :load_phone_tenant_map, %{})
  end

  describe "start_link " do
    test ":ok pid", ~M[test] do
      # When
      assert {:ok, pid} = TenantObserver.start_link(name: test)
      assert Process.alive?(pid)
      Process.exit(pid, :kill)
    end
  end

  describe "invalid_phone_numbers" do
    test "get empty list" do
      # When
      assert [] = TenantObserver.invalid_phone_numbers()
    end
  end

  describe "handle_continue(:load_phone_tenant_map)  " do
    test "tenant load_phone_tenant_map" do
      state = %State{deps: %{state: TenantObserverStateParrot}}

      # When
      {:noreply, _state} = TenantObserver.handle_continue(:load_phone_tenant_map, state)

      # Then
      assert_receive {:load_phone_tenant_map, _state}
    end
  end

  describe "handle_info()  " do
    test "tenant invalid_phone_number" do
      state = %State{deps: %{state: TenantObserverStateParrot}}

      content = %{phone: "+15005551111"}

      event = %AppCount.Core.DomainEvent{
        content: content,
        name: "invalid_phone_number",
        source: AppCount.Adapters.TwilioAdapter,
        topic: "sms"
      }

      # When
      {:noreply, _state} = TenantObserver.handle_info(event, state)

      # Then
      assert_receive {:update_invalid_phone_numbers, ^content, _state}
    end

    test "tenant changes to payment_status: cash" do
      tenant_id = 333
      state = %State{deps: %{state: TenantObserverStateParrot}}

      event = %DomainEvent{
        topic: "tenants__tenants",
        name: "changed",
        content: %{changes: %{payment_status: "cash"}},
        subject_name: "AppCount.Tenants.Tenant",
        subject_id: tenant_id
      }

      # When
      {:noreply, _state} = TenantObserver.handle_info(event, state)

      # Then
      assert_receive {:payment_status_changed_to_cash, ^tenant_id, _state}
    end

    test "tenant activates autopay" do
      tenant_id = 333
      state = %State{deps: %{state: TenantObserverStateParrot}}

      event = %DomainEvent{
        topic: "tenants__tenants",
        name: "changed",
        content: %{changes: %{active: true}},
        subject_name: "AppCount.Tenants.Tenant",
        subject_id: tenant_id
      }

      # When
      {:noreply, _state} = TenantObserver.handle_info(event, state)

      # Then
      assert_receive {:autopay_activated_notification, ^tenant_id, _state}
    end

    test "tenant deactivates autopay" do
      tenant_id = 345
      state = %State{deps: %{state: TenantObserverStateParrot}}

      event = %DomainEvent{
        topic: "tenants__tenants",
        name: "changed",
        content: %{changes: %{active: false}},
        subject_name: "AppCount.Tenants.Tenant",
        subject_id: tenant_id
      }

      # When
      {:noreply, _state} = TenantObserver.handle_info(event, state)

      # Then
      assert_receive {:autopay_deactivated_notification, ^tenant_id, _state}
    end

    test "tenant created" do
      tenant_id = 333
      state = %State{deps: %{state: TenantObserverStateParrot}}

      event = %DomainEvent{
        topic: "tenants__tenants",
        name: "created",
        content: %{},
        subject_name: "AppCount.Tenants.Tenant",
        subject_id: tenant_id
      }

      # When
      {:noreply, _state} = TenantObserver.handle_info(event, state)

      # Then
      # New Tenant, nothing to do
      refute_receive {:payment_status_changed_to_cash, ^tenant_id, _state}
    end
  end
end
