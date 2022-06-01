defmodule AppCountWeb.Controllers.API.CredentialSetControllerTest do
  use AppCountWeb.ConnCase
  alias AppCount.Settings.CredentialSetRepo
  @moduletag :credential_set_controller

  setup do
    admin = AppCount.UserHelper.new_admin(%{roles: ["Super Admin"]})

    {:ok, %{credential_set: insert(:credential_set), admin: admin}}
  end

  test "index", %{credential_set: credential_set, admin: admin, conn: conn} do
    resp =
      conn
      |> admin_request(admin)
      |> get("http://administration.example.com/api/credential_sets")
      |> json_response(200)

    assert length(resp) == 1
    assert hd(resp)["provider"] == credential_set.provider
  end

  test "create", %{admin: admin, conn: conn} do
    new_values = %{
      "provider" => "Something",
      "credentials" => [
        %{"name" => "username", "value" => "User"},
        %{"name" => "password", "value" => "password123"}
      ]
    }

    params = %{"credential_set" => new_values}

    conn
    |> admin_request(admin)
    |> post("http://administration.example.com/api/credential_sets", params)
    |> json_response(200)

    assert CredentialSetRepo.get_by(provider: "Something")
  end

  test "update", %{credential_set: credential_set, admin: admin, conn: conn} do
    new_values = %{
      "credentials" => [
        %{"name" => "username", "value" => "User"},
        %{"name" => "password", "value" => "password123"}
      ]
    }

    params = %{"credential_set" => new_values}

    conn
    |> admin_request(admin)
    |> patch("http://administration.example.com/api/credential_sets/#{credential_set.id}", params)
    |> json_response(200)

    reloaded = CredentialSetRepo.get(credential_set.id)
    assert length(reloaded.credentials) == 2
    assert hd(reloaded.credentials).value == "User"
  end

  test "delete", %{credential_set: credential_set, admin: admin, conn: conn} do
    conn = admin_request(conn, admin)

    # When
    result =
      delete(conn, "http://administration.example.com/api/credential_sets/#{credential_set.id}")

    assert json_response(result, 200)
    refute AppCount.Settings.CredentialSetRepo.get(credential_set.id)
  end
end
