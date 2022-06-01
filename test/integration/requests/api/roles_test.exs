defmodule AppCountWeb.Requests.API.RolesTest do
  use AppCountWeb.ConnCase
  use AppCount.DataCase
  alias AppCount.Admins.Role

  setup do
    action1 = insert(:action, [], prefix: "public")
    action2 = insert(:action, [], prefix: "public")
    {:ok, action1: action1, action2: action2, role: insert(:role)}
  end

  test "GET /api/roles?tree=true", %{conn: conn, action1: action1} do
    admin = %{
      id: 1,
      property_ids: [],
      roles: ["Super Admin"],
      features: %{action1.module.name => true}
    }

    response =
      conn
      |> admin_request(admin)
      |> get("https://administration.example.com/api/roles?tree=true")
      |> json_response(200)

    expected = %{
      action1.module.name => [
        %{
          "description" => action1.description,
          "id" => action1.id,
          "module_id" => action1.module_id,
          "permission_type" => action1.permission_type,
          "slug" => Slug.slugify(action1.description, separator: ?_)
        }
      ]
    }

    assert response == expected
  end

  test "GET /api/roles", %{conn: conn, role: role} do
    admin = %{id: 1, property_ids: [], roles: ["Super Admin"]}

    response =
      conn
      |> admin_request(admin)
      |> get("https://administration.example.com/api/roles")
      |> json_response(200)

    expected = [
      %{
        "id" => role.id,
        "name" => role.name,
        "permissions" => Jason.decode!(Jason.encode!(role.permissions))
      }
    ]

    assert response == expected
  end

  test "POST /api/roles", %{conn: conn} do
    admin = %{id: 1, property_ids: [], roles: ["Super Admin"]}

    params = %{
      "role" => %{
        "name" => "Test Role 1",
        "permissions" => %{"properties" => "write"}
      }
    }

    conn
    |> admin_request(admin)
    |> post("https://administration.example.com/api/roles", params)
    |> json_response(200)

    assert Repo.get_by(Role, [name: "Test Role 1"], prefix: "dasmen")
  end

  test "PATCH /api/roles/:id", %{conn: conn, role: role} do
    admin = %{id: 1, property_ids: [], roles: ["Super Admin"]}

    params = %{
      "role" => %{
        "name" => "New Role Name"
      }
    }

    conn
    |> admin_request(admin)
    |> patch("https://administration.example.com/api/roles/#{role.id}", params)
    |> json_response(200)

    assert Repo.get(Role, role.id, prefix: "dasmen").name == "New Role Name"
  end

  test "DELETE /api/roles/:id", %{conn: conn, role: role} do
    admin = %{id: 1, property_ids: [], roles: ["Super Admin"]}

    conn
    |> admin_request(admin)
    |> delete("https://administration.example.com/api/roles/#{role.id}")
    |> json_response(200)

    refute Repo.get(Role, role.id, prefix: "dasmen")
  end
end
