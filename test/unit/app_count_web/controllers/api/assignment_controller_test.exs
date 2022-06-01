defmodule AppCountWeb.API.AssignmentControllerTest do
  use AppCountWeb.ConnCase
  alias AppCount.Support.PropertyBuilder, as: PropBuilder
  alias AppCount.Core.ClientSchema

  defmodule MaintenanceParrot do
    use TestParrot
    parrot(:maintenance, :assign_order, %{})
    parrot(:maintenance, :assign_orders, %{})
    parrot(:maintenance, :bug_resident_about_rating, %{})
    parrot(:maintenance, :rate_assignment, %{})
    parrot(:maintenance, :tech_dispatched, %{})
    parrot(:maintenance, :callback_assignment, {:ok, "Yo"})
    parrot(:maintenance, :revoke_assignments, %{})
    parrot(:maintenance, :delete_assignment, %{})
    parrot(:maintenance, :revoke_assignment, %{})
  end

  setup do
    builder =
      PropBuilder.new(:create)
      |> PropBuilder.add_property()
      |> PropBuilder.add_unit()
      |> PropBuilder.add_super_admin()

    admin = PropBuilder.get_requirement(builder, :admin)

    ~M[admin]
  end

  @tag subdomain: "administration"
  test "create", ~M[admin, conn] do
    params = %{"tech_id" => 0, "order_id" => 1}

    conn =
      conn
      |> assign(:maintenance, MaintenanceParrot)
      |> admin_request(admin)
      |> post(Routes.api_assignment_path(conn, :create, %{"assignment" => params}))

    id = admin.id
    assert json_response(conn, 200) == %{}
    assert_receive {:assign_order, %ClientSchema{name: "dasmen", attrs: "1"}, "0", ^id}
  end

  # This test passes when the controller does not work and fails when the controller does work.
  @tag subdomain: "administration"
  test "create multiple", ~M[admin, conn] do
    params = %{"order_ids" => [1, 2, 3], "tech_id" => 0}

    conn =
      conn
      |> assign(:maintenance, MaintenanceParrot)
      |> admin_request(admin)
      |> post(Routes.api_assignment_path(conn, :create, params))

    id = admin.id
    assert json_response(conn, 200) == %{}

    assert_receive {:assign_orders, %ClientSchema{name: "dasmen", attrs: ["1", "2", "3"]}, "0",
                    ^id}
  end

  @tag subdomain: "administration"
  test "update bugs resident", ~M[admin, conn] do
    params = %{"id" => 2, "bug" => "bug"}

    conn =
      conn
      |> assign(:maintenance, MaintenanceParrot)
      |> admin_request(admin)
      |> patch(Routes.api_assignment_path(conn, :update, params["id"]), params)

    received_admin = conn.assigns.admin
    id = "#{params["id"]}"
    assert json_response(conn, 200) == %{}
    assert_receive {:bug_resident_about_rating, ^received_admin, ^id}
  end

  @tag subdomain: "administration"
  test "edit rating", ~M[admin, conn] do
    params = %{"id" => 2, "rating" => 5}

    conn =
      conn
      |> assign(:maintenance, MaintenanceParrot)
      |> admin_request(admin)
      |> patch(Routes.api_assignment_path(conn, :update, params["id"]), params)

    id = "#{params["id"]}"
    rating = params["rating"]
    assert json_response(conn, 200) == %{}
    assert_receive {:rate_assignment, ^id, ^rating}
  end

  @tag subdomain: "administration"
  test "update tech dispatched", ~M[admin, conn] do
    params = %{"assignment_id" => 0, "time" => 1}

    conn =
      conn
      |> assign(:maintenance, MaintenanceParrot)
      |> admin_request(admin)
      |> patch(Routes.api_assignment_path(conn, :update, params["assignment_id"]), params)

    id = %AppCount.Core.ClientSchema{attrs: params["assignment_id"], name: "dasmen"}
    rating = params["time"]
    assert json_response(conn, 200) == %{}
    assert_receive {:tech_dispatched, ^id, ^rating}
  end

  @tag subdomain: "administration"
  test "update callback assignment", ~M[admin, conn] do
    params = %{"id" => 0, "callback" => "blargh", "note" => "Hi!"}

    conn =
      conn
      |> assign(:maintenance, MaintenanceParrot)
      |> admin_request(admin)
      |> patch(Routes.api_assignment_path(conn, :update, params["id"]), params)

    assert json_response(conn, 200) == %{}
    assert_receive :callback_assignment

    # later we'll need to mock out the Repo.get call in this function to get around assignment being nil
  end

  @tag subdomain: "administration"
  test "update callback assignment if error", ~M[admin, conn] do
    MaintenanceParrot.say_callback_assignment(
      {:error,
       %{
         errors: [
           {"error:", {"no such assignment", "irrelevant string,controller gets first 2"}}
         ]
       }}
    )

    params = %{"id" => 0, "callback" => "blargh", "note" => "Hi!"}

    conn =
      conn
      |> assign(:maintenance, MaintenanceParrot)
      |> admin_request(admin)
      |> patch(Routes.api_assignment_path(conn, :update, params["id"]), params)

    assert json_response(conn, 501) == "Error: no such assignment"
    assert_receive :callback_assignment
  end

  @tag subdomain: "administration"
  test "update callback assignment with no note", ~M[admin, conn] do
    params = %{"id" => 0, "callback" => "blargh"}

    conn =
      conn
      |> assign(:maintenance, MaintenanceParrot)
      |> admin_request(admin)
      |> patch(Routes.api_assignment_path(conn, :update, params["id"]), params)

    assert json_response(conn, 200) == %{}

    assert_receive {:callback_assignment, %AppCount.Core.ClientSchema{attrs: nil, name: "dasmen"}}

    # later we'll need to mock out the Repo.get call in this function to get around assignment being nil
  end

  @tag subdomain: "administration"
  test "revoke by assignment ids", ~M[admin, conn] do
    params = %{"assignment_ids" => [4783, 68, 352]}

    conn =
      conn
      |> assign(:maintenance, MaintenanceParrot)
      |> admin_request(admin)
      |> delete(Routes.api_assignment_path(conn, :delete, hd(params["assignment_ids"])), params)

    assert json_response(conn, 200) == %{}

    assert_receive {:revoke_assignments,
                    %AppCount.Core.ClientSchema{attrs: [4783, 68, 352], name: "dasmen"}}
  end

  @tag subdomain: "administration"
  test "revoke by assignment id", ~M[admin, conn] do
    params = %{"id" => 943}

    id = params["id"] |> to_string()

    conn =
      conn
      |> assign(:maintenance, MaintenanceParrot)
      |> admin_request(admin)
      |> delete(Routes.api_assignment_path(conn, :delete, params["id"]), params)

    assert json_response(conn, 200) == %{}

    assert_receive {:revoke_assignment, %AppCount.Core.ClientSchema{attrs: ^id, name: "dasmen"}}
  end

  @tag subdomain: "administration"
  test "hard delete by assignment id", ~M[admin, conn] do
    params = %{
      "id" => 7329,
      "trueDelete" => "GIBBERISH"
    }

    conn =
      conn
      |> assign(:maintenance, MaintenanceParrot)
      |> admin_request(admin)
      |> delete(Routes.api_assignment_path(conn, :delete, params["id"]), params)

    recieved_admin = conn.assigns.admin
    id = params["id"] |> to_string()

    assert json_response(conn, 200) == %{}
    assert_receive {:delete_assignment, ^recieved_admin, ^id}
  end
end
