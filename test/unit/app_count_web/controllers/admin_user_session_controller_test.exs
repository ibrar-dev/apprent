defmodule AppCountWeb.AdminUserSessionControllerTest do
  use AppCountWeb.ConnCase

  setup do
    {:ok, account: insert(:user_account)}
  end

  test "redirects with valid token", %{conn: conn, account: account} do
    redirect_url =
      conn
      |> admin_request(%{roles: ["Super Admin"]})
      |> get("https://administration.example.com/user_accounts/#{account.id}")
      |> redirected_to(302)

    assert redirect_url =~ "://residents."

    {:ok, user_struct} =
      redirect_url
      |> String.split("/")
      |> List.last()
      |> AppCountWeb.Token.verify()

    assert user_struct.account_id == account.id
  end
end
