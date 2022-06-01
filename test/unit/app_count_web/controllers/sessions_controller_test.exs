defmodule AppCountWeb.Controllers.SessionControllerTest do
  use AppCountWeb.ConnCase
  alias AppCountWeb.SessionController

  setup do
    admin = AppCount.UserHelper.new_admin()

    {:ok, [admin: admin]}
  end

  test "new session page loads", %{conn: conn} do
    response =
      conn
      |> get("http://administration.example.com/sessions")
      |> html_response(200)

    assert response =~ "AppRent"
  end

  test "authenticates admin", %{conn: conn, admin: admin} do
    req = %{
      "create" => %{
        "email" => admin.email,
        "password" => "test_password"
      }
    }

    new_conn =
      conn
      |> bypass_through(AppCountWeb.Router, [:browser])
      |> post("http://administration.example.com/sessions")
      |> SessionController.create(req)

    assert is_binary(get_session(new_conn, :admin_token))
  end

  test "fails on bad auth", %{conn: conn, admin: admin} do
    req = %{
      "create" => %{
        "email" => admin.email,
        "password" => "test_password_bad"
      }
    }

    new_conn =
      conn
      |> bypass_through(AppCountWeb.Router, [:browser])
      |> post("http://administration.example.com/sessions")
      |> SessionController.create(req)

    refute get_session(new_conn, :admin_token)
  end
end
