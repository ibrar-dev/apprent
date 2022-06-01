defmodule AppCount.Accounts.AccountRepoTest do
  use AppCount.DataCase
  alias AppCount.Accounts.Account
  alias AppCount.Accounts.AccountRepo

  def create_an_account do
    alias AppCount.Tenants.Tenant

    {:ok, tenant} =
      Tenant.new("Mickey", "Mouse")
      |> Tenant.changeset(%{})
      |> AppCount.Repo.insert()

    attrs = %{
      password: "secret agent man",
      tenant_id: tenant.id,
      username: "AccountHolder-#{Enum.random(1..100_000)}",
      property_id: Factory.insert(:property).id
    }

    account =
      Account.new(attrs)
      |> Account.changeset(%{allow_sms: true})
      |> AppCount.Repo.insert!()

    account
  end

  setup do
    [_builder, tenant] =
      PropBuilder.new(:create)
      |> PropBuilder.add_property()
      |> PropBuilder.add_unit()
      |> PropBuilder.add_tenant()
      |> PropBuilder.add_customer_ledger()
      |> PropBuilder.add_tenancy()
      |> PropBuilder.add_tenant_account()
      |> PropBuilder.get([:tenant])

    ~M[tenant]
  end

  test "get account from id" do
    account = create_an_account()
    assert AccountRepo.get(account.id)
  end

  test "get_account_extras/1 struct", ~M[tenant] do
    res = AccountRepo.get_account_extras(tenant.id)

    assert is_nil(res.autopay)
    assert length(res.logins) == 0
  end
end
