defmodule AppCountWeb.API.NoteControllerTest do
  use AppCountWeb.ConnCase
  alias AppCount.Support.PropertyBuilder, as: PropBuilder

  defmodule MaintenanceParrot do
    use TestParrot
    parrot(:maintenance, :get_maintenance_notes, %{"assigned" => [%{"id" => 1234}]})
    parrot(:maintenance, :get_vendor_notes, %{"assigned" => [%{"id" => 9988}]})
  end

  setup do
    builder =
      PropBuilder.new(:create)
      |> PropBuilder.add_super_admin()

    admin = PropBuilder.get_requirement(builder, :admin)

    ~M[admin]
  end

  @tag subdomain: "administration"
  test "index retrives maintenance notes", ~M[conn, admin] do
    params = %{"fetch_notes" => true, "order_type" => "Maintenance", "order_id" => 1234}

    conn = assign(conn, :maintenance, MaintenanceParrot)
    conn = conn |> admin_request(admin)

    # When
    conn = get(conn, Routes.api_note_path(conn, :index, params))

    assert json_response(conn, 200) == %{"assigned" => [%{"id" => 1234}]}

    assert_receive {:get_maintenance_notes,
                    %AppCount.Core.ClientSchema{attrs: "1234", name: "dasmen"}, :private}
  end

  @tag subdomain: "administration"
  test "index retrives vendor notes", ~M[conn, admin] do
    params = %{"fetch_notes" => true, "order_type" => "Vendor", "order_id" => 9988}

    conn = assign(conn, :maintenance, MaintenanceParrot)
    conn = conn |> admin_request(admin)

    # When
    conn = get(conn, Routes.api_note_path(conn, :index, params))

    assert json_response(conn, 200) == %{"assigned" => [%{"id" => 9988}]}
    assert_receive {:get_vendor_notes, "9988"}
  end

  @tag subdomain: "administration"
  test "create", ~M[conn, admin] do
    params = %{
      "newNote" => %{
        "text" => "This is some noteaa!",
        "order_id" => insert(:order).id,
        "mentions" => [%{"name" => "something", "email" => "someone@example.com", "id" => 1}]
      }
    }

    resp =
      conn
      |> admin_request(admin)
      |> post(Routes.api_note_path(conn, :create), params)
      |> json_response(200)

    assert resp == %{}
  end
end
