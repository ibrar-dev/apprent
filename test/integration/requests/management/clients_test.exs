defmodule AppCountWeb.Requests.Management.ClientsTest do
  use AppCountWeb.ConnCase
  alias AppCount.Public.ClientModule
  alias AppCount.Public.Client

  setup do
    modules = [
      insert(:module, [name: "Core"], prefix: "public"),
      insert(:module, [], prefix: "public"),
      insert(:module, [], prefix: "public"),
      insert(:module, [], prefix: "public")
    ]
    {:ok, modules: modules}
  end

  test "GET /clients", %{conn: conn} do
    response =
      conn
      |> apprent_admin_request
      |> get("http://management.example.com/clients")
      |> html_response(200)

    assert response =~ "AppRent"
    # default client will always be there
    assert response =~ "dasmen"
  end

  test "GET /clients/:id/edit", %{conn: conn} do
    client = AppCount.Public.get_client_by_schema("dasmen")

    response =
      conn
      |> apprent_admin_request
      |> get("http://management.example.com/clients/#{client.id}/edit")
      |> html_response(200)

    assert response =~ "AppRent"
    assert response =~ "Edit Client"
  end

  test "PATCH /clients/:id", %{conn: conn, modules: modules} do
    [module1, module2, module3, module4] = modules
    client = AppCount.Public.get_client_by_schema("dasmen")

    params = %{
      "client_modules" => %{
        "0" => %{"enabled" => "true", "module_id" => module1.id},
        "1" => %{"enabled" => "true", "module_id" => module2.id},
        "2" => %{"enabled" => "true", "module_id" => module3.id},
        "3" => %{"enabled" => "false", "module_id" => module4.id}
      },
      "name" => "Wildly unique name"
    }

    conn
    |> apprent_admin_request
    |> patch("http://management.example.com/clients/#{client.id}", %{"client" => params})

    assert Repo.get_by(ClientModule, client_id: client.id, module_id: module2.id).enabled
    refute Repo.get_by(ClientModule, client_id: client.id, module_id: module4.id).enabled
  end

  test "POST /clients", %{conn: conn, modules: modules} do
    [module1, module2, module3, module4] = modules

    params = %{
      "client_schema" => "wildly_new",
      "client_modules" => %{
        "0" => %{"enabled" => "true", "module_id" => module1.id},
        "1" => %{"enabled" => "true", "module_id" => module2.id},
        "2" => %{"enabled" => "true", "module_id" => module3.id},
        "3" => %{"enabled" => "false", "module_id" => module4.id}
      },
      "name" => "Wildly unique name",
      "users" => %{
        "0" => %{
          "email" => "rrrrr@example.com",
          "name" => "rrrrrr",
          "password" => "password",
          "username" => "rrrrrrr"
        }
      }
    }

    conn
    |> apprent_admin_request
    |> assign(:create_schema, false)
    |> post("http://management.example.com/clients", %{"client" => params})

    client = Repo.get_by(Client, name: "Wildly unique name")

    assert Repo.get_by(ClientModule, client_id: client.id, module_id: module2.id).enabled
    assert Repo.get_by(ClientModule, client_id: client.id, module_id: module3.id).enabled
    refute Repo.get_by(ClientModule, client_id: client.id, module_id: module4.id).enabled
  end

  test "GET /clients/new", %{conn: conn} do
    response =
      conn
      |> apprent_admin_request
      |> get("http://management.example.com/clients/new")
      |> html_response(200)

    assert response =~ "AppRent"
    assert response =~ "New Client"
  end
end
