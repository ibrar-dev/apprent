defmodule AppCount.Accounts.LockRepoTest do
  use AppCount.DataCase
  alias AppCount.Accounts.LockRepo
  alias AppCount.Core.ClientSchema

  setup do
    [builder, tenant_account] =
      PropBuilder.new(:create)
      |> PropBuilder.add_property()
      |> PropBuilder.add_unit()
      |> PropBuilder.add_tenant()
      |> PropBuilder.add_customer_ledger()
      |> PropBuilder.add_tenancy()
      |> PropBuilder.add_tenant_account()
      |> PropBuilder.get([:tenant_account])

    times =
      AppTime.new()
      |> AppTime.plus_to_naive(:yesterday, days: -1)
      |> AppTime.plus_to_naive(:now, minutes: 0)
      |> AppTime.times()

    ~M[builder, tenant_account, times]
  end

  describe "account_lock/1" do
    test "returns nil if no lock", ~M[tenant_account] do
      res = LockRepo.account_lock(ClientSchema.new("dasmen", tenant_account.id))

      assert is_nil(res)
    end

    test "returns one if only one", ~M[builder, tenant_account] do
      builder
      |> PropBuilder.add_account_lock()

      res = LockRepo.account_lock(ClientSchema.new("dasmen", tenant_account.id))

      refute is_nil(res)
    end

    test "returns most recent if there are multiple", ~M[builder, tenant_account, times] do
      builder
      |> PropBuilder.add_account_lock(updated_at: times.yesterday)
      |> PropBuilder.add_account_lock(reason: "This is a reason")

      res = LockRepo.account_lock(ClientSchema.new("dasmen", tenant_account.id))

      refute is_nil(res)
      assert res.reason == "This is a reason"
    end
  end

  describe "active_lock/1" do
    test "returns nil if no lock", ~M[tenant_account] do
      res = LockRepo.active_lock(ClientSchema.new("dasmen", tenant_account.id))

      assert is_nil(res)
    end

    test "returns one if only one", ~M[builder, tenant_account] do
      builder
      |> PropBuilder.add_account_lock()

      res = LockRepo.active_lock(ClientSchema.new("dasmen", tenant_account.id))

      refute is_nil(res)
    end

    test "returns most recent if there are multiple", ~M[builder, tenant_account, times] do
      builder
      |> PropBuilder.add_account_lock(updated_at: times.yesterday)
      |> PropBuilder.add_account_lock(reason: "This is a reason")

      res = LockRepo.active_lock(ClientSchema.new("dasmen", tenant_account.id))

      refute is_nil(res)
      assert res.reason == "This is a reason"
    end

    test "returns nil if most recent is disabled", ~M[builder, tenant_account] do
      builder
      |> PropBuilder.add_account_lock(enabled: false)

      res = LockRepo.active_lock(ClientSchema.new("dasmen", tenant_account.id))

      assert is_nil(res)
    end
  end

  describe "account_locked/1" do
    test "returns false if no lock", ~M[tenant_account] do
      res = LockRepo.account_locked(ClientSchema.new("dasmen", tenant_account.id))

      refute res
    end

    test "returns true if one", ~M[builder, tenant_account] do
      builder
      |> PropBuilder.add_account_lock()

      res = LockRepo.account_locked(ClientSchema.new("dasmen", tenant_account.id))

      assert res
    end

    test "returns true if there are multiple", ~M[builder, tenant_account, times] do
      builder
      |> PropBuilder.add_account_lock(updated_at: times.yesterday)
      |> PropBuilder.add_account_lock()

      res = LockRepo.account_locked(ClientSchema.new("dasmen", tenant_account.id))

      assert res
    end

    test "returns false if most recent has been disabled", ~M[builder, tenant_account, times] do
      builder
      |> PropBuilder.add_account_lock(updated_at: times.yesterday)
      |> PropBuilder.add_account_lock(enabled: false)

      res = LockRepo.account_locked(ClientSchema.new("dasmen", tenant_account.id))

      refute res
    end
  end
end
