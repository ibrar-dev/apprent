defmodule AppCountWeb.Requests.API.AdminProfileTest do
  use AppCountWeb.ConnCase
  use AppCount.DataCase
  alias AppCount.Admins.Profile

  setup do
    {:ok, admin: insert(:admin)}
  end

  test "POST /api/admin_profile", %{conn: conn, admin: admin} do
    params = %{
      "admin_profile" => %{
        "active" => false,
        "admin_id" => admin.id,
        "title" => "Mr. Big Shot"
      }
    }

    response =
      conn
      |> admin_request(admin)
      |> post("https://administration.example.com/api/admin_profile", params)
      |> json_response(200)

    assert response == %{}
    assert Repo.get_by(Profile, [admin_id: admin.id], prefix: "dasmen")
  end

  test "PATCH /api/admin_profile/:id", %{conn: conn, admin: admin} do
    id = insert(:profile).id

    params = %{
      "admin_profile" => %{
        "active" => false,
        "bio" => "This is my Bio",
        "title" => "Mr. Big Shot"
      }
    }

    response =
      conn
      |> admin_request(admin)
      |> patch("https://administration.example.com/api/admin_profile/#{id}", params)
      |> json_response(200)

    assert response == %{}
    reloaded = Repo.get(Profile, id, prefix: "dasmen")

    assert reloaded.bio == "This is my Bio"
    assert reloaded.active == false
  end

  test "DELETE /api/admin_profile/:id", %{conn: conn, admin: admin} do
    id = insert(:profile).id

    response =
      conn
      |> admin_request(admin)
      |> delete("https://administration.example.com/api/admin_profile/#{id}")
      |> json_response(200)

    assert response == %{}
    refute Repo.get(Profile, id, prefix: "dasmen")
  end
end
