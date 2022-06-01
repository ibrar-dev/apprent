defmodule AppCountWeb.Controllers.Users.PackageControllerTest do
  use AppCountWeb.ConnCase

  setup do
    account =
      insert(:user_account)
      |> AppCount.UserHelper.new_account()

    insert(:lease, tenants: [account.tenant])
    {:ok, account: account}
  end

  test "user packages page loads", %{conn: conn, account: account} do
    response =
      conn
      |> user_request(account)
      |> get("http://residents.example.com/packages")
      |> html_response(200)

    assert response =~ "#{account.tenant.first_name} #{account.tenant.last_name}"
    assert response =~ "Packages Requiring Pickup"
  end
end
