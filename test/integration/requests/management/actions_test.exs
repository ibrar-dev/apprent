defmodule AppCountWeb.Requests.Management.ActionsTest do
  use AppCountWeb.ConnCase

  setup do
    {:ok,
     action: insert(:action, [], prefix: "public"), module: insert(:module, [], prefix: "public")}
  end

  test "GET /actions", %{conn: conn, action: action} do
    response =
      conn
      |> apprent_admin_request
      |> get("http://management.example.com/actions/")
      |> html_response(200)

    assert response =~ "Actions"
    assert response =~ action.description
  end

  test "GET /actions?module_id", %{conn: conn, action: action} do
    response =
      conn
      |> apprent_admin_request
      |> get("http://management.example.com/actions?module_id=#{action.module_id}")
      |> html_response(200)

    assert response =~ "Actions: #{action.module.name}"
    assert response =~ action.description
  end

  test "GET /actions/:id/edit", %{conn: conn, action: action} do
    response =
      conn
      |> apprent_admin_request
      |> get("http://management.example.com/actions/#{action.id}/edit")
      |> html_response(200)

    assert response =~ "Permission type"
  end

  test "POST /actions", %{conn: conn, module: module} do
    params = %{
      "action" => %{
        "description" => "SSSS",
        "module_id" => module.id,
        "permission_type" => "yes-no"
      }
    }

    conn
    |> apprent_admin_request
    |> post("http://management.example.com/actions", params)

    assert AppCountAuth.ActionRepo.get_by([module_id: module.id], prefix: "public").description ==
             "SSSS"
  end

  test "PATCH /actions/:id", %{conn: conn, action: action} do
    conn
    |> apprent_admin_request
    |> patch("http://management.example.com/actions/#{action.id}", %{
      "action" => %{"description" => "SSSS"}
    })

    assert AppCountAuth.ActionRepo.get(action.id, prefix: "public").description == "SSSS"
  end

  test "delete", %{conn: conn, action: action} do
    conn
    |> apprent_admin_request
    |> delete("http://management.example.com/actions/#{action.id}")

    refute AppCountAuth.ActionRepo.get(action.id, prefix: "public")
  end
end
