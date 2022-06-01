defmodule AppCount.Accounts.AccountTest do
  use AppCount.DataCase
  alias AppCount.Accounts.Account

  def new_account() do
    alias AppCount.Tenants.Tenant

    {:ok, tenant} =
      Tenant.new("Mickey", "Mouse")
      |> Tenant.changeset(%{})
      |> AppCount.Repo.insert()

    attrs = %{
      password: "secret agent man",
      tenant_id: tenant.id,
      username: "AccountHolder-#{Enum.random(1..100_000)}",
      property_id: insert(:property).id
    }

    Account.new(attrs)
  end

  test "create" do
    assert new_account()
  end

  test "changeset" do
    account = new_account()

    changeset = Account.changeset(account, %{allow_sms: true})
    assert changeset.valid?
  end

  test "store in db" do
    account = new_account()

    result =
      Account.changeset(account, %{allow_sms: true})
      |> AppCount.Repo.insert()

    assert {:ok, stored_account} = result
    assert stored_account.id
    assert stored_account.inserted_at
    assert stored_account.allow_sms == true
  end

  describe "language inclusion" do
    test "allows english" do
      account = new_account()

      changeset = Account.changeset(account, %{preferred_language: "english"})
      assert changeset.valid?
    end

    test "allows spanish" do
      account = new_account()

      changeset = Account.changeset(account, %{preferred_language: "spanish"})
      assert changeset.valid?
    end

    test "disallows others" do
      account = new_account()

      changeset = Account.changeset(account, %{preferred_language: "klingon"})
      refute changeset.valid?
    end
  end

  describe "hash_pwd" do
    test "key is binary" do
      account = Account.hash_pwd(%{"password" => "secret"})
      assert account["encrypted_password"]
    end

    test "key is an atom" do
      account = Account.hash_pwd(%{password: "secret"})
      assert account.encrypted_password
    end
  end
end
