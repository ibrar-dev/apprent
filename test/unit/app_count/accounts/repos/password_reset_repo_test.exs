defmodule AppCount.Accounts.PasswordResetRepoTest do
  use AppCount.DataCase
  alias AppCount.Accounts.PasswordResetRepo
  alias AppCount.Support.AccountBuilder

  setup do
    builder =
      PropBuilder.new(:create)
      |> PropBuilder.add_property()
      |> PropBuilder.add_admin()

    property =
      builder
      |> PropBuilder.get_requirement(:property)

    tenant =
      builder
      |> PropBuilder.add_unit()
      |> PropBuilder.add_tenant()
      |> PropBuilder.add_lease()
      |> PropBuilder.get_requirement(:tenant)

    account =
      AccountBuilder.new(:create)
      |> AccountBuilder.put_requirement(:tenant, tenant)
      |> AccountBuilder.put_requirement(:property, property)
      |> AccountBuilder.add_account()
      |> AccountBuilder.get_requirement(:account)

    admin = PropBuilder.get_requirement(builder, :admin)

    ~M[account, admin]
  end

  describe "create_password_reset(nil, nil)" do
    test "nil account_id returns and error" do
      assert {:error, changeset} = PasswordResetRepo.create(nil, nil)
      assert ~s[can't be blank] in errors_on(changeset).account_id
    end
  end

  describe "create_password_reset(account_id, nil)" do
    test "account_id with nil admin_id returns password_reset", ~M[account] do
      {:ok, password_reset} = PasswordResetRepo.create(account.id, nil)
      assert password_reset.account_id == account.id
    end
  end

  describe "create_password_reset(account_id, admin_id)" do
    test "account_id with admin_id returns password_reset", ~M[account, admin] do
      {:ok, password_reset} = PasswordResetRepo.create(account.id, admin.id)
      assert password_reset.account_id == account.id
      assert password_reset.admin_id == admin.id
    end
  end
end
