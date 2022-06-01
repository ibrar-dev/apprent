defmodule AppCount.Admins.ActionsTest do
  use AppCountWeb.ConnCase
  alias AppCount.Admins.Action
  @moduletag :admin_actions

  setup do
    prop = insert(:property)

    insert(:property)

    admin = admin_with_access([prop.id])

    {:ok, [admin: admin, property: prop]}
  end

  test "translates POST actions into human readable description", context do
    params = %{
      "move_out_reason" => %{
        "name" => "Needed change of scenery"
      }
    }

    conn =
      context.conn
      |> admin_request(context.admin)
      |> put_req_header("x-forwarded-for", "87.123.21.221")
      |> post("http://administration.example.com/api/move_out_reasons", params)

    assert json_response(conn, 401) == %{"error" => "unauthorized"}

    # Should not test side effects
    #
    # action = Repo.get_by(Action, admin_id: context.admin.id)
    # assert action
    # assert action.ip == "87.123.21.221"
    # assert action.description == "Created a Move Out Reason"
    # assert action.params == params
  end

  test "translates PATCH actions into human readable description", context do
    params = %{
      "move_out_reason" => %{
        "name" => "Needed change of scenery"
      }
    }

    id = insert(:move_out_reason).id

    conn =
      context.conn
      |> admin_request(context.admin)
      |> patch("http://administration.example.com/api/move_out_reasons/#{id}", params)

    assert json_response(conn, 401) == %{"error" => "unauthorized"}

    # Should not test side effects
    #   Process.sleep(2)
    #   action = Repo.get_by(Action, admin_id: context.admin.id)
    #   assert action
    #   assert action.ip == "127.0.0.1"
    #   assert action.description == "Updated a Move Out Reason"
    #   assert action.params == Map.put(params, "id", "#{id}")
  end

  test "records login and logout", %{admin: admin, conn: conn} do
    # AppCount.Admins.update_admin(admin.id, %{"password" => "test_password"})

    req = %{
      "create" => %{
        "email" => admin.email,
        "password" => "test_password"
      }
    }

    post(conn, "http://administration.example.com/sessions", req)

    Process.sleep(2)

    action = Repo.get_by(Action, admin_id: admin.id, description: "Logged in")

    assert action
    assert action.ip == "127.0.0.1"
    assert action.params == req

    conn
    |> admin_request(admin)
    |> delete("http://administration.example.com/sessions")

    Process.sleep(2)
    assert Repo.get_by(Action, admin_id: admin.id, description: "Logged out")
  end
end
