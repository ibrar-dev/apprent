defmodule AppCount.Public.SyncUsersTest do
  use AppCount.DataCase
  alias AppCount.Public.SyncUsers
  alias AppCount.Public.User

  setup do
    admin = insert(:admin)

    account =
      insert(:user_account)
      |> AppCount.UserHelper.new_account()

    client = AppCount.Public.get_client_by_schema("dasmen")
    {:ok, admin: admin, account: account, client: client}
  end

  test "syncs login data to public.users", %{admin: admin, account: account, client: client} do
    SyncUsers.sync_all_users(["dasmen"])

    expected_params = [
      type: "Admin",
      tenant_account_id: admin.id,
      username: admin.email,
      client_id: client.id
    ]

    user = Repo.get_by(User, expected_params, prefix: "public")
    assert user

    assert Repo.get(AppCount.Admins.Admin, admin.id, prefix: client.client_schema).public_user_id ==
             user.id

    expected_params = [
      type: "Tenant",
      tenant_account_id: account.id,
      username: account.username,
      client_id: client.id
    ]

    user = Repo.get_by(User, expected_params, prefix: "public")
    assert user

    assert Repo.get(AppCount.Accounts.Account, account.id, prefix: client.client_schema).public_user_id ==
             user.id
  end

  @tag skip: """
         TODO in order to implement this test we will need the ability to have multiple clients and schemas in test.
         TBD how to best accomplish that without slowing down the test suite too much.
         One thing that will need to be done regardless is to squish down the migrations.
       """
  test "syncs login data to public.users and resolves for duplicate usernames"
end
