defmodule AppCountWeb.Controllers.API.AccountControllerTest do
  use AppCount.Case
  use AppCountWeb.ConnCase
  import AppCount.Factory
  alias AppCount.Repo
  alias AppCount.Accounting.Account
  @moduletag :account_controller

  setup do
    insert(:account, name: "Account w/ desc", description: "Some weird description")

    admin = AppCount.UserHelper.new_admin(%{roles: ["Accountant"]})
    {:ok, admin: admin}
  end

  test "index", %{admin: admin, conn: conn} do
    conn
    |> admin_request(admin)
    |> get("http://administration.example.com/api/accounts")
    |> json_response(200)
    |> assert
  end

  test "create", %{admin: admin, conn: conn} do
    params = %{"name" => "Created Account"}

    conn
    |> admin_request(admin)
    |> post("http://administration.example.com/api/accounts", %{"account" => params})
    |> json_response(200)

    assert Repo.get_by(Account, name: "Created Account")
  end

  test "update", %{admin: admin, conn: conn} do
    acc = insert(:account)
    params = %{"name" => "Updated Account", "description" => "Beep Beep"}

    conn
    |> admin_request(admin)
    |> patch("http://administration.example.com/api/accounts/#{acc.id}", %{"account" => params})
    |> json_response(200)

    assert Repo.get_by(Account, id: acc.id, name: "Updated Account", description: "Beep Beep")
  end

  test "delete", %{admin: admin, conn: conn} do
    acc = insert(:account)

    conn
    |> admin_request(admin)
    |> delete("http://administration.example.com/api/accounts/#{acc.id}")
    |> json_response(200)

    refute Repo.get(Account, acc.id)
  end
end
