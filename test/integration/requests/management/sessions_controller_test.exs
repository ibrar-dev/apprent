defmodule AppCountWeb.Requests.Management.SessionsTest do
  use AppCountWeb.ConnCase
  alias AppCountWeb.Management.SessionController

  setup do
    {:ok, user} = AppCount.UserHelper.new_app_rent_user()

    {:ok, [user: user]}
  end

  test "new session page loads", %{conn: conn} do
    response =
      conn
      |> get("http://management.example.com/sessions")
      |> html_response(200)

    assert response =~ "AppRent"
  end

  test "authenticates app rent user", %{conn: conn, user: user} do
    req = %{
      "create" => %{
        "email" => user.username,
        "password" => "test_password"
      }
    }

    new_conn =
      conn
      |> bypass_through(AppCountWeb.Router, [:browser])
      |> post("http://management.example.com/sessions")
      |> SessionController.create(req)

    assert is_binary(get_session(new_conn, :apprent_manager_token))
  end

  test "fails on bad auth", %{conn: conn, user: user} do
    req = %{
      "create" => %{
        "email" => user.username,
        "password" => "test_password_bad"
      }
    }

    new_conn =
      conn
      |> bypass_through(AppCountWeb.Router, [:browser])
      |> post("http://management.example.com/sessions")
      |> SessionController.create(req)

    refute get_session(new_conn, :apprent_manager_token)
  end
end
