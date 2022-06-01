defmodule AppCountWeb.Controllers.API.V1.SessionControllerTest do
  use AppCountWeb.ConnCase
  alias AppCountWeb.API.SessionController
  # alias AppCount.Admins

  setup do
    admin = AppCount.UserHelper.new_admin()
    {:ok, [admin: admin]}
  end

  test "authenticates admin", %{conn: conn, admin: admin} do
    new_conn =
      SessionController.create(conn, %{"email" => admin.email, "password" => "test_password"})

    assert is_binary(json_response(new_conn, 200)["token"])
  end

  test "token auth works", %{conn: conn, admin: admin} do
    token = AppCountWeb.Token.token(auth_user_struct(admin))

    resp =
      conn
      |> put_req_header("x-admin-token", token)
      |> put_req_header("content-type", "application/json")
      |> get("http://administration.example.com/api/tenants")

    assert is_list(json_response(resp, 200))
  end

  test "fails on bad auth", %{conn: conn, admin: admin} do
    new_conn =
      SessionController.create(conn, %{"email" => admin.email, "password" => "api_girl_test"})

    assert json_response(new_conn, 200)["error"] == "Invalid Authentication"
  end
end
