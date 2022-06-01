defmodule AppCountWeb.Requests.Management.ModulesTest do
  use AppCountWeb.ConnCase

  setup do
    {:ok, module: insert(:module, [], prefix: "public")}
  end

  test "index", %{conn: conn, module: module} do
    response =
      conn
      |> apprent_admin_request
      |> get("http://management.example.com/modules/")
      |> html_response(200)

    assert response =~ "Modules"
    assert response =~ module.name
  end

  test "edit", %{conn: conn, module: module} do
    response =
      conn
      |> apprent_admin_request
      |> get("http://management.example.com/modules/#{module.id}/edit")
      |> html_response(200)

    assert response =~ "Name"
  end

  test "create", %{conn: conn} do
    params = %{
      "module" => %{
        "name" => "SSSS"
      }
    }

    conn
    |> apprent_admin_request
    |> post("http://management.example.com/modules", params)

    assert AppCountAuth.ModuleRepo.get_by([name: "SSSS"], prefix: "public")
  end

  test "update", %{conn: conn, module: module} do
    conn
    |> apprent_admin_request
    |> patch("http://management.example.com/modules/#{module.id}", %{
      "module" => %{"name" => "SSSS"}
    })

    assert AppCountAuth.ModuleRepo.get(module.id, prefix: "public").name == "SSSS"
  end

  test "delete", %{conn: conn, module: module} do
    conn
    |> apprent_admin_request
    |> delete("http://management.example.com/modules/#{module.id}")

    refute AppCountAuth.ModuleRepo.get(module.id, prefix: "public")
  end
end
