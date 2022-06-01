defmodule AppCountWeb.Controllers.Users.SessionControllerTest do
  use AppCountWeb.ConnCase
  @moduletag :session_controller

  setup do
    account =
      insert(:user_account)
      |> AppCount.UserHelper.new_account()

    {:ok, account: account}
  end

  test "user login page works", %{conn: conn} do
    resp =
      conn
      |> get("http://residents.example.com/login")
      |> html_response(200)

    assert resp =~ "Access Your Account"
  end

  @tag :slow
  test "user login works", %{conn: conn, account: account} do
    req = %{"email" => account.username, "password" => "test_password"}

    conn
    |> post("http://residents.example.com/login", login: req)
    |> get_session(:user_token)
    |> is_binary
    |> assert
  end

  test "fails on bad auth", %{conn: conn, account: account} do
    req = %{"email" => account.tenant.email, "password" => "bad_password"}

    conn
    |> post("http://residents.example.com/login", login: req)
    |> get_session(:user_token)
    |> is_binary
    |> refute
  end

  test "user logout works", %{conn: conn, account: account} do
    conn
    |> user_request(account)
    |> delete("http://resindets.example.com/logout")
    |> get_session(:user_token)
    |> refute
  end
end
