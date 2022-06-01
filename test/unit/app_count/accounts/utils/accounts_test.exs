defmodule AppCount.Accounts.Utils.AccountsTest do
  use AppCount.DataCase
  alias AppCount.Support.AccountBuilder
  alias AppCount.Accounts
  alias AppCount.Tenants.TenantRepo
  alias AppCount.Core.ClientSchema

  @moduletag :accounts_utils

  setup do
    [builder, property, tenant] =
      PropBuilder.new(:create)
      |> PropBuilder.add_property()
      |> PropBuilder.add_unit()
      |> PropBuilder.add_tenant()
      |> PropBuilder.add_customer_ledger()
      |> PropBuilder.add_tenancy()
      |> PropBuilder.get([:property, :tenant])

    tenant_without_account =
      builder
      |> PropBuilder.add_tenant()
      |> PropBuilder.add_unit()
      |> PropBuilder.add_customer_ledger()
      |> PropBuilder.add_tenancy()
      |> PropBuilder.get_requirement(:tenant)
      |> Map.merge(Map.new(account: nil))

    [builder, second_tenant_without_account] =
      builder
      |> PropBuilder.add_property()
      |> PropBuilder.add_tenant()
      |> PropBuilder.add_unit()
      |> PropBuilder.add_customer_ledger()
      |> PropBuilder.add_tenancy()
      |> PropBuilder.get([:tenant])

    second_tenant_without_account =
      second_tenant_without_account
      |> Map.merge(Map.new(account: nil))

    tenant_with_account =
      AccountBuilder.new(:create)
      |> AccountBuilder.put_requirement(:tenant, tenant)
      |> AccountBuilder.put_requirement(:property, property)
      |> AccountBuilder.add_account()
      |> AccountBuilder.get_requirement(:tenant)
      |> Repo.preload(:account)

    tenant_without_email =
      builder
      |> PropBuilder.add_tenant()
      |> PropBuilder.add_unit()
      |> PropBuilder.add_customer_ledger()
      |> PropBuilder.add_tenancy()
      |> PropBuilder.get_requirement(:tenant)

    tenant = %{
      no_email: tenant_without_email,
      has_account: tenant_with_account,
      has_no_account: tenant_without_account,
      second: second_tenant_without_account
    }

    ~M[property, tenant]
  end

  describe "delete_account/1" do
    @tag :slow
    test "delete_account actually deletes", ~M[tenant] do
      client = AppCount.Public.get_client_by_schema("dasmen")

      {:ok, _struct} =
        Accounts.delete_account(
          ClientSchema.new(client.client_schema, tenant.has_account.account.id)
        )

      freshly_wiped_tenant =
        Repo.get(AppCount.Tenants.Tenant, tenant.has_account.id, prefix: client.client_schema)
        |> Repo.preload(:account)

      assert is_nil(freshly_wiped_tenant.account)
    end

    @tag :slow
    test "delete_account deletes account in list", ~M[tenant] do
      tenant_list = [tenant.has_account]
      client = AppCount.Public.get_client_by_schema("dasmen")

      Accounts.delete_account(ClientSchema.new(client.client_schema, tenant_list))

      tenant_with_account =
        Repo.get(AppCount.Tenants.Tenant, tenant.has_account.id, prefix: client.client_schema)
        |> Repo.preload(:account)

      assert is_nil(tenant_with_account.account)
    end
  end

  describe "create_tenant_account/1" do
    @tag :slow
    test "create_tenant_account works for one account", ~M[tenant] do
      {:ok, new_account} = Accounts.create_tenant_account(tenant.has_no_account.id)

      refute is_nil(new_account)
    end

    @tag :slow
    test "create_tenant_account works for multiple accounts", ~M[tenant] do
      list_of_tenants = [tenant.has_no_account, tenant.second]

      [{:ok, first_new_account}, {:ok, second_new_account}] =
        Accounts.create_tenant_account(list_of_tenants)

      refute is_nil(first_new_account)
      refute is_nil(second_new_account)
    end
  end

  @tag :slow
  test "reset_all_tenants works", ~M[property, tenant] do
    client = AppCount.Public.get_client_by_schema("dasmen")

    Accounts.reset_all_accounts(ClientSchema.new(client.client_schema, property.id))

    results = TenantRepo.tenants_for_property([property.id]) |> Repo.preload(:account)

    post_tenant_with_account = Enum.find(results, fn x -> x.id == tenant.has_account.id end)

    post_tenant_without_account = Enum.find(results, fn x -> x.id == tenant.has_no_account.id end)

    assert post_tenant_with_account.id == tenant.has_account.id
    assert post_tenant_without_account.id == tenant.has_no_account.id
    refute is_nil(post_tenant_without_account.account)
    assert post_tenant_with_account.account.id != tenant.has_account.account.id
    refute Enum.any?(results, fn x -> is_nil(x.email) end)
  end

  @tag :slow
  test "send_welcome_email/1", %{tenant: %{has_account: tenant}} do
    {:ok, post_account} = Accounts.send_welcome_email(tenant.account.id)

    assert tenant.account.encrypted_password != post_account.encrypted_password
  end

  @tag :slow
  test "account_lock", %{tenant: %{has_account: tenant}} do
    Accounts.lock_account(tenant.id, "I don't like him")
    schema = ClientSchema.new("dasmen", tenant.account.id)
    assert Accounts.active_lock(schema)
    # make sure it works when there are multiple active locks
    Accounts.lock_account(tenant.id, "I just really REALLY don't like him")
    assert Accounts.active_lock(schema)
  end

  test "get_property_id", %{tenant: %{has_account: tenant}, property: property} do
    assert Accounts.get_property_id(tenant.account) == property.id
  end
end
