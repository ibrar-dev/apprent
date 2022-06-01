defmodule AppCountWeb.Controllers.Users.AccountControllerTest do
  use AppCountWeb.ConnCase

  setup do
    account =
      insert(:user_account)
      |> AppCount.UserHelper.new_account()

    {:ok, account: account}
  end

  test "user account page loads", %{conn: conn, account: account} do
    response =
      conn
      |> user_request(account)
      |> get("http://residents.example.com/profile")
      |> html_response(200)

    assert response =~ "#{account.tenant.first_name} #{account.tenant.last_name}"
    assert response =~ "Account Details"
  end
end
