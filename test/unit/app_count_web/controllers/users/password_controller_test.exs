defmodule AppCountWeb.Controllers.Users.PasswordControllerTest do
  use AppCountWeb.ConnCase
  use Bamboo.Test, shared: true
  @moduletag :passwords

  setup do
    account =
      insert(:user_account)
      |> AppCount.UserHelper.new_account()

    lease = insert(:tenancy, tenant: account.tenant)
    {:ok, account: account, property: lease.unit.property}
  end

  test "user reset password screen works", %{conn: conn} do
    response =
      conn
      |> get("http://administration.example.com/forgot-password")
      |> html_response(200)

    assert response =~ "Enter Your Account Username"
  end

  test "user reset password screen with token works", %{conn: conn, account: account} do
    token = AppCount.Accounts.Utils.Passwords.token(account.user.id)

    response =
      conn
      |> get("http://administration.example.com/forgot-password?token=#{token}")
      |> html_response(200)

    assert response =~ "Enter Your New Password"
  end

  test "user reset password request works", %{conn: conn, account: account} do
    reset = %{"username" => account.username}
    conn = post(conn, "http://administration.example.com/forgot-password", reset: reset)
    assert redirected_to(conn, 302) == "/login"
    assert get_flash(conn)["success"] == "Reset password email sent to #{account.tenant.email}"

    assert_email_delivered_with(
      subject: "[AppRent] Reset your password",
      html_body: ~r/Someone has requested a link to change your password/,
      to: [nil: account.tenant.email]
    )
  end

  @tag :slow
  test "user update password request works", %{conn: conn, account: account} do
    token = AppCount.Accounts.Utils.Passwords.token(account.user.id)
    new_password = "zany-password"
    reset = %{"password" => new_password, "token" => token, "confirmation" => new_password}
    conn = patch(conn, "http://administration.example.com/forgot-password", reset: reset)
    assert redirected_to(conn, 302) == "/login"
    assert get_flash(conn)["success"] == "Password reset successfully"

    {:ok, %AppCountAuth.Users.Tenant{} = user} =
      AppCount.Public.Auth.authenticate_user(account.username, new_password)

    assert user.account_id == account.id
  end

  test "user reset password error handling", %{conn: conn} do
    reset = %{"username" => "randomUsername"}
    conn = post(conn, "http://administration.example.com/forgot-password", reset: reset)
    assert redirected_to(conn, 302) == "/forgot-password"
    assert get_flash(conn)["error"] == "Username not found."
  end

  test "user update password error handling", %{conn: conn, account: account} do
    token = AppCount.Accounts.Utils.Passwords.token(account.user.id)
    new_password = "zany-password"
    reset = %{"password" => new_password, "token" => token, "confirmation" => "new_password"}
    conn = patch(conn, "http://administration.example.com/forgot-password", reset: reset)
    assert redirected_to(conn, 302) == "/forgot-password?token=#{token}"
    assert get_flash(conn)["error"] == "Password does not match confirmation"
  end
end
