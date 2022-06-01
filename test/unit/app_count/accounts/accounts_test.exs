defmodule AppCount.Accounts.AccountsTest do
  use AppCount.DataCase
  import AppCount.LeasingHelper
  alias AppCount.Accounts
  alias AppCount.Accounts.Account
  alias AppCount.Repo

  setup do
    now = AppCount.current_time()
    start_date = Timex.shift(now, days: -2)
    end_date = Timex.shift(now, days: 365)
    %{tenancies: [t]} = insert_lease(%{charges: [], start_date: start_date, end_date: end_date})
    {:ok, [future_resident: insert(:tenant), resident: t.tenant]}
  end

  test "create_tenant_account throws error with no current lease", %{future_resident: t} do
    assert {:error, "Tenant has no current lease"} == Accounts.create_tenant_account(t.id)
  end

  test "create_tenant_account and get_account work with current lease", %{resident: r} do
    Accounts.create_tenant_account(r.id)
    %{tenant_id: tenant_id, encrypted_password: enc} = Repo.get_by(Account, tenant_id: r.id)
    assert tenant_id == r.id
    assert Bcrypt.verify_pass("test_password", enc)
    assert Accounts.get_account(r.id)
  end

  test "authentication works", %{resident: t} do
    {:ok, acc} = Accounts.create_tenant_account(t.id)
    assert Accounts.authenticate_account(acc.username, "test_password")
  end

  test "authentication returns false with nil password" do
    assert Accounts.authenticate_account("username", nil) == false
  end

  @tag :slow
  test "update works", %{resident: t} do
    # SETUP
    Accounts.create_tenant_account(t.id)
    %{id: id, username: username} = Repo.get_by(Account, tenant_id: t.id)

    # WHEN
    Accounts.update_account(id, %{"password" => "star_ship"})

    # THEN
    assert Accounts.authenticate_account(username, "star_ship")
  end

  test "setting preferred_language works", %{resident: tenant} do
    # SETUP
    Accounts.create_tenant_account(tenant.id)
    %{id: id, preferred_language: "english"} = Repo.get_by(Account, tenant_id: tenant.id)

    # WHEN
    {:ok, account} = Accounts.update_account(id, %{"preferred_language" => "spanish"})

    # THEN
    assert account.preferred_language == "spanish"
  end

  describe "various verify email works" do
    test "no email" do
      result = Accounts.verify_tenant(%{"email" => "gibberish@gibberish.com"})

      assert result ==
               {:error,
                "We are unable to find an apartment associated with your email address. Please try entering a different email or contact AppRent support for further assistance."}
    end

    test "no account", %{resident: r} do
      {:ok, acc} = Accounts.verify_tenant(%{"email" => r.email})
      assert Accounts.authenticate_account(acc.username, "test_password")
    end

    test "sends password forgot email", %{resident: r} do
      Accounts.create_tenant_account(r.id)
      result = Accounts.verify_tenant(%{"email" => r.email})

      assert result ==
               {:success,
                "A link to reset your password has been sent to the email address provided."}
    end
  end
end
