defmodule AppCountWeb.Controllers.API.ChargeCodeControllerTest do
  use AppCount.Case
  use AppCountWeb.ConnCase
  @moduletag :charge_code_controller

  setup do
    {:ok, admin: %{roles: ["Accountant"]}}
  end

  @tag subdomain: "administration"
  test "index", ~M[admin, conn] do
    conn =
      conn
      |> admin_request(admin)
      |> get(Routes.api_charge_code_path(conn, :index))

    assert json_response(conn, 200) == []
  end

  @tag subdomain: "administration"
  test "create", ~M[admin, conn] do
    params = %{
      "charge_code" => %{"code" => "codey", "name" => "Codey", "account_id" => 5}
    }

    conn =
      conn
      |> admin_request(admin)
      |> post(Routes.api_charge_code_path(conn, :create, params))

    assert json_response(conn, 200) == %{}
  end

  @tag subdomain: "administration"
  test "update", ~M[admin, conn] do
    params = %{
      "id" => insert(:charge_code).id,
      "charge_code" => %{"code" => "codey", "name" => "Codey"}
    }

    conn =
      conn
      |> admin_request(admin)
      |> patch(Routes.api_charge_code_path(conn, :update, params["id"]), params)

    assert json_response(conn, 200) == %{}
  end

  @tag subdomain: "administration"
  test "delete", ~M[admin, conn] do
    conn =
      conn
      |> admin_request(admin)
      |> delete(Routes.api_charge_code_path(conn, :delete, insert(:charge_code).id))

    assert json_response(conn, 200) == %{}
  end
end
