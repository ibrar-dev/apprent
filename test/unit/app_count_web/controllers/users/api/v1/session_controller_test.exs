defmodule AppCountWeb.Controllers.Users.API.V1.SessionControllerTest do
  use AppCountWeb.ConnCase
  alias AppCountWeb.Users.API.V1.SessionController

  setup do
    account =
      insert(:user_account)
      |> AppCount.UserHelper.new_account()

    {:ok, account: account}
  end

  test "login fails without account_id", %{conn: conn, account: account} do
    request_body = %{
      "username" => account.username,
      "password" => "test_password"
    }

    AppCount.Public.UserRepo.get(account.user.id, prefix: "public")
    |> AppCount.Public.UserRepo.update(%{tenant_account_id: nil})

    new_conn =
      conn
      |> bypass_through(AppCountWeb.Router, [:public_api])
      |> post("http://administration.example.com/sessions")
      |> SessionController.create(request_body)

    assert body = json_response(new_conn, 200)

    assert is_binary(body["token"])
    assert body["preferred_language"] == "english"
  end

  test "API login works", %{conn: conn, account: account} do
    request_body = %{
      "username" => account.username,
      "password" => "test_password"
    }

    new_conn =
      conn
      |> bypass_through(AppCountWeb.Router, [:public_api])
      |> post("http://administration.example.com/sessions")
      |> SessionController.create(request_body)

    assert body = json_response(new_conn, 200)

    assert is_binary(body["token"])
    assert body["preferred_language"] == "english"
  end

  test "API login works with metadata", ~M[conn, account] do
    # SETUP
    request_body = %{
      "username" => account.username,
      "password" => "test_password",
      "login_metadata" => %{"foo" => "bar", "baz" => "qux"}
    }

    # WHEN
    conn
    |> bypass_through(AppCountWeb.Router, [:public_api])
    |> post("http://administration.example.com/sessions")
    |> SessionController.create(request_body)

    # THEN
    [login] = Repo.last(AppCount.Accounts.Login)
    assert login.account_id == account.id
    assert login.login_metadata == %{"foo" => "bar", "baz" => "qux"}
    assert login.type == "app"
  end

  test "sets language appropriately - English", ~M[conn, account] do
    request_body = %{
      "username" => account.username,
      "password" => "test_password",
      "language" => "en"
    }

    new_conn =
      conn
      |> bypass_through(AppCountWeb.Router, [:public_api])
      |> post("http://administration.example.com/sessions")
      |> SessionController.create(request_body)

    assert body = json_response(new_conn, 200)

    assert is_binary(body["token"])
    assert body["preferred_language"] == "english"
  end

  test "sets language appropriately - Spanish", ~M[conn, account] do
    request_body = %{
      "username" => account.username,
      "password" => "test_password",
      "language" => "es"
    }

    new_conn =
      conn
      |> bypass_through(AppCountWeb.Router, [:public_api])
      |> post("http://administration.example.com/sessions")
      |> SessionController.create(request_body)

    assert body = json_response(new_conn, 200)

    assert is_binary(body["token"])
    assert body["preferred_language"] == "spanish"
  end

  test "bad API login works", %{conn: conn, account: account} do
    request_body = %{
      "username" => account.username,
      "password" => "password23"
    }

    new_conn =
      conn
      |> bypass_through(AppCountWeb.Router, [:public_api])
      |> post("http://administration.example.com/sessions")
      |> SessionController.create(request_body)

    assert is_binary(json_response(new_conn, 401)["error"])
  end
end
