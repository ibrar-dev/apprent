defmodule AppCount.Core.TenantObserver.StateTest do
  use AppCount.DataCase
  alias AppCount.Core.TenantObserver.State
  alias AppCount.Support.AccountBuilder
  alias AppCount.Tenants.TenantRepo
  alias AppCount.Core.PhoneNumber

  setup do
    [prop_builder, property, tenant] =
      PropBuilder.new(:create)
      |> PropBuilder.add_property()
      |> PropBuilder.add_processor()
      |> PropBuilder.add_unit()
      |> PropBuilder.add_tenant(phone: "(555) 111-2222")
      |> PropBuilder.add_lease()
      |> PropBuilder.add_customer_ledger()
      |> PropBuilder.add_tenancy()
      |> PropBuilder.get([:property, :tenant])

    [account_builder, account] =
      AccountBuilder.new(:create)
      |> AccountBuilder.put_requirement(:tenant, tenant)
      |> AccountBuilder.put_requirement(:property, property)
      |> AccountBuilder.add_account()
      |> AccountBuilder.get([:account])

    ~M[tenant, account, account_builder, prop_builder]
  end

  describe "update_invalid_phone_numbers" do
    test "update DBwith zero" do
      content = %{phone: "+15005551111"}

      state = %State{phone_tenant_map: %{}}

      # When
      _state = State.update_invalid_phone_numbers(content, state)

      # Then
      # No effect
    end

    test "update DBwith one", ~M[tenant] do
      content = %{phone: "+15005551111"}
      AppCount.Tenants.TenantRepo.update(tenant, content)

      state = %State{phone_tenant_map: %{content.phone => [tenant.id]}}

      # When
      _state = State.update_invalid_phone_numbers(content, state)

      # Then
      mod_tenant = AppCount.Tenants.TenantRepo.get(tenant.id)
      assert mod_tenant.invalid_phone == "+15005551111"
    end

    test "update DBwith two with SAME PHONE", ~M[tenant, prop_builder] do
      first_tenant = tenant

      [_prop_builder, second_tenant] =
        prop_builder
        |> PropBuilder.add_tenant(phone: "(555) 111-2222")
        |> PropBuilder.get([:tenant])

      content = %{phone: "+15005551111"}
      AppCount.Tenants.TenantRepo.update(first_tenant, content)
      AppCount.Tenants.TenantRepo.update(second_tenant, content)

      state = %State{phone_tenant_map: %{content.phone => [tenant.id, second_tenant.id]}}

      # When
      _state = State.update_invalid_phone_numbers(content, state)

      # Then
      # first_tenant
      mod_first_tenant = AppCount.Tenants.TenantRepo.get(first_tenant.id)
      assert mod_first_tenant.invalid_phone == "+15005551111"
      # second_tenant
      mod_second_tenant = AppCount.Tenants.TenantRepo.get(second_tenant.id)
      assert mod_second_tenant.invalid_phone == "+15005551111"
    end

    test "skip nil phone", ~M[tenant] do
      content = %{phone: nil}
      AppCount.Tenants.TenantRepo.update(tenant, content)

      state = %State{phone_tenant_map: %{content.phone => [tenant.id]}}

      # When
      _state = State.update_invalid_phone_numbers(content, state)

      # Then
      mod_tenant = AppCount.Tenants.TenantRepo.get(tenant.id)
      assert mod_tenant.invalid_phone == ""
    end

    test "skip blank phone", ~M[tenant] do
      content = %{phone: ""}
      AppCount.Tenants.TenantRepo.update(tenant, content)

      state = %State{phone_tenant_map: %{content.phone => [tenant.id]}}

      # When
      _state = State.update_invalid_phone_numbers(content, state)

      # Then
      mod_tenant = AppCount.Tenants.TenantRepo.get(tenant.id)
      assert mod_tenant.invalid_phone == ""
    end
  end

  describe "load_phone_tenant_map" do
    test "load one tenant with number", ~M[tenant] do
      state = %State{phone_tenant_map: %{}}

      canonical_phone = PhoneNumber.new(tenant.phone) |> PhoneNumber.dial_string()
      # When
      state = State.load_phone_tenant_map(state)

      # Then
      assert state.phone_tenant_map == %{canonical_phone => [tenant.id]}
    end

    test "load two tenants with SAME number", ~M[tenant, prop_builder] do
      first_tenant = tenant

      [_prop_builder, second_tenant] =
        prop_builder
        |> PropBuilder.add_tenant(phone: "(555) 111-2222")
        |> PropBuilder.get([:tenant])

      state = %State{phone_tenant_map: %{}}

      canonical_phone = PhoneNumber.new(first_tenant.phone) |> PhoneNumber.dial_string()
      # When
      state = State.load_phone_tenant_map(state)

      # Then
      assert state.phone_tenant_map == %{canonical_phone => [second_tenant.id, first_tenant.id]}
    end

    test "skip blank phone", ~M[tenant] do
      content = %{phone: ""}
      AppCount.Tenants.TenantRepo.update(tenant, content)

      state = %State{phone_tenant_map: %{content.phone => [tenant.id]}}

      # When
      state = State.load_phone_tenant_map(state)

      # Then
      assert state.phone_tenant_map == %{}
    end

    test "skip nil phone", ~M[tenant] do
      content = %{phone: nil}
      AppCount.Tenants.TenantRepo.update(tenant, content)

      state = %State{phone_tenant_map: %{content.phone => [tenant.id]}}

      # When
      state = State.load_phone_tenant_map(state)

      # Then
      assert state.phone_tenant_map == %{}
    end
  end

  describe "autopay_deactivated_notification/2" do
    test "sends the email", ~M[tenant] do
      state = %State{}

      result = State.autopay_deactivated_notification(tenant.id, state)

      assert %Bamboo.Email{subject: "[AppRent] Autopay Deactivated"} = result.outgoing_message
    end
  end

  describe "autopay_activated_notification/2" do
    test "sends the email", ~M[tenant, account_builder] do
      # Add an Autopay
      account_builder
      |> AccountBuilder.add_payment_source()
      |> AccountBuilder.add_autopay()

      state = %State{}

      result = State.autopay_activated_notification(tenant.id, state)

      assert %Bamboo.Email{subject: "[AppRent] Autopay Activated"} = result.outgoing_message
    end
  end

  describe "payment_status_changed_to_cash/2" do
    test "w/o autopay", ~M[tenant] do
      state = %State{}

      # When
      result = State.payment_status_changed_to_cash(tenant.id, state)

      # Then
      {:ok, tenant} = TenantRepo.aggregate(tenant.id)
      refute AppCount.Tenants.Tenant.autopay?(tenant)

      assert %Bamboo.Email{subject: "[AppRent] Account Locked"} = result.outgoing_message
    end

    test "with active autopay", ~M[tenant, account_builder] do
      state = %State{}

      account_builder
      |> AccountBuilder.add_payment_source()
      |> AccountBuilder.add_autopay()

      # client = AppCount.Public.get_client_by_schema("dasmen")

      # When
      result = State.payment_status_changed_to_cash(tenant.id, state)
      # result = State.payment_status_changed_to_cash(tenant.id, state, client.client_schema)

      # Then
      {:ok, tenant} = TenantRepo.aggregate(tenant.id)
      refute AppCount.Tenants.Tenant.autopay?(tenant)

      assert %Bamboo.Email{subject: "[AppRent] Account Locked"} = result.outgoing_message
    end

    test "with inactive autopay", ~M[tenant, account_builder] do
      state = %State{}

      account_builder
      |> AccountBuilder.add_payment_source()
      |> AccountBuilder.add_autopay(active: false)

      # When
      result = State.payment_status_changed_to_cash(tenant.id, state)

      # Then
      {:ok, tenant} = TenantRepo.aggregate(tenant.id)
      refute AppCount.Tenants.Tenant.autopay?(tenant)
      assert %Bamboo.Email{subject: "[AppRent] Account Locked"} = result.outgoing_message
    end

    test "with no account at all", ~M[tenant, account] do
      # Tenant does not have an account - just tenancy
      Repo.delete(account)

      state = %State{}

      result = State.payment_status_changed_to_cash(tenant.id, state)

      {:ok, tenant} = TenantRepo.aggregate(tenant.id)
      assert is_nil(tenant.account)
      refute AppCount.Tenants.Tenant.autopay?(tenant)

      # TODO: Ideally we'd listen for an "email sent" domain event, which definitely
      # gets emitted but doesn't get received unless we run just this test file in
      # isolation. I'm not sure how to fix it, so we do this instead.
      assert %Bamboo.Email{subject: "[AppRent] Account Locked"} = result.outgoing_message
    end
  end
end
