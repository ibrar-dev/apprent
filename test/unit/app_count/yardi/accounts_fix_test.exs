defmodule AppCount.Yardi.AccountsFixCase do
  use AppCount.DataCase
  import AppCount.LeasingHelper
  @moduletag :yardi_import_accounts_fix

  setup do
    %{tenancies: [%{tenant: new_tenant}]} = insert_lease()

    options = [
      first_name: new_tenant.first_name,
      last_name: new_tenant.last_name,
      email: new_tenant.email
    ]

    account = insert(:user_account, tenant: insert(:tenant, options))
    {:ok, new: new_tenant, account: account}
  end

  test "create_accounts creates accounts for tenants that have none", %{new: new} do
    pre = AppCount.Repo.get_by(AppCount.Accounts.Account, tenant_id: new.id)
    AppCount.Yardi.AccountsFix.create_accounts()
    post = AppCount.Repo.get_by(AppCount.Accounts.Account, tenant_id: new.id)

    assert is_nil(pre)
    assert not is_nil(post)
  end
end
