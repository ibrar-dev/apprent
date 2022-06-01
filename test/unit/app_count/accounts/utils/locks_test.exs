defmodule AppCount.Accounts.Utils.LocksTest do
  use AppCount.DataCase
  alias AppCount.Accounts
  alias AppCount.Accounts.Lock
  @moduletag :account_locks

  setup do
    account =
      insert(:user_account)
      |> AppCount.UserHelper.new_account()

    {:ok, account: account}
  end

  test "create_lock", %{account: account} do
    Accounts.create_lock(%{account_id: account.id, reason: "I don't even know"})
    assert Repo.get_by(Lock, account_id: account.id, reason: "I don't even know", enabled: true)
  end

  test "update_lock" do
    lock = insert(:user_account_lock)
    Accounts.update_lock(lock.id, %{enabled: false, comments: "Kind of a mistake"})
    updated = Repo.get(Lock, lock.id)
    assert updated.comments == "Kind of a mistake"
    refute updated.enabled
  end

  test "delete_lock" do
    lock = insert(:user_account_lock)
    Accounts.delete_lock(lock.id)
    refute Repo.get(Lock, lock.id)
  end

  test "lock_account", %{account: account} do
    Accounts.lock_account(account.tenant_id, "Ridiculous reason")
    assert Repo.get_by(Lock, account_id: account.id, reason: "Ridiculous reason", enabled: true)
  end
end
