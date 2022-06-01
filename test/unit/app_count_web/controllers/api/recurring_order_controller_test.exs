defmodule AppCountWeb.API.RecurringOrderControllerTest do
  use AppCount.Case
  use AppCountWeb.ConnCase
  alias AppCount.Support.PropertyBuilder, as: PropBuilder

  defmodule MaintenanceParrot do
    use TestParrot

    parrot(:maintenance, :create_recurring_order, %{"order" => "500 nutter butters confirmed"})
    parrot(:maintenance, :update_recurring_order, %{"order" => "555 gummy bears confirmed"})
    parrot(:maintenance, :delete_recurring_order, "Recurring order deleted")
  end

  setup do
    builder =
      PropBuilder.new(:create)
      |> PropBuilder.add_property()
      |> PropBuilder.add_factory_admin()

    admin = PropBuilder.get_requirement(builder, :admin)

    params = %{
      "recurring_order" => %{
        "order" => "500 nutter butters"
      },
      "id" => 687
    }

    ~M[admin, params]
  end

  @tag subdomain: "administration"
  test "create", ~M[admin, conn, params] do
    conn =
      assign(conn, :maintenance, MaintenanceParrot)
      |> admin_request(admin)

    # When
    conn = post(conn, Routes.api_recurring_order_path(conn, :create, params), params)

    expected_args =
      params["recurring_order"]
      |> Map.put("admin_id", conn.assigns.admin.id)

    assert json_response(conn, 200) == %{}

    assert_receive {:create_recurring_order,
                    %AppCount.Core.ClientSchema{
                      attrs: ^expected_args,
                      name: "dasmen"
                    }}
  end

  @tag subdomain: "administration"
  test "update", ~M[admin, conn, params] do
    id = params["id"] |> to_string()
    order_to_update = params["recurring_order"]

    conn =
      assign(conn, :maintenance, MaintenanceParrot)
      |> admin_request(admin)

    # When
    conn = patch(conn, Routes.api_recurring_order_path(conn, :update, params["id"]), params)

    assert json_response(conn, 200) == %{}
    assert_receive {:update_recurring_order, ^id, ^order_to_update}
  end

  @tag subdomain: "administration"
  test "delete", ~M[admin, conn, params] do
    id = params["id"] |> to_string()

    conn =
      assign(conn, :maintenance, MaintenanceParrot)
      |> admin_request(admin)

    # When
    conn = delete(conn, Routes.api_recurring_order_path(conn, :delete, params["id"]), params)

    assert json_response(conn, 200) == %{}
    assert_receive {:delete_recurring_order, ^id}
  end
end
