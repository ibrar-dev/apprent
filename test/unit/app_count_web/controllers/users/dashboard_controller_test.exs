defmodule AppCountWeb.Controllers.Users.DashboardControllerTest do
  use AppCountWeb.ConnCase

  setup do
    account =
      insert(:user_account)
      |> AppCount.UserHelper.new_account()

    insert(:tenancy, tenant: account.tenant)
    {:ok, account: account}
  end

  test "user dashboard loads", %{conn: conn, account: account} do
    response =
      conn
      |> user_request(account)
      |> get("http://residents.example.com/")
      |> html_response(200)

    assert response =~ "#{account.tenant.first_name} #{account.tenant.last_name}"
  end
end
