defmodule AppCountWeb.Controllers.API.MaintenancePartControllerTest do
  use AppCount.Case
  use AppCountWeb.ConnCase
  alias AppCount.Support.PropertyBuilder, as: PropBuilder
  @moduletag :maintenance_part_controller

  defmodule MaintenanceParrot do
    use TestParrot
    parrot(:maintenance, :create_part, ["something"])
    parrot(:maintenance, :update_part, ["something"])
    parrot(:maintenance, :remove_part, ["something"])
  end

  setup do
    builder =
      PropBuilder.new(:create)
      |> PropBuilder.add_property()
      |> PropBuilder.add_unit()
      |> PropBuilder.add_factory_admin()
      |> PropBuilder.add_parent_category()
      |> PropBuilder.add_category()
      |> PropBuilder.add_work_order_on_unit()

    admin = PropBuilder.get_requirement(builder, :admin)
    order = PropBuilder.get_requirement(builder, :work_order)
    part = %{order: order, id: 7237}

    ~M[admin, order, part]
  end

  @tag subdomain: "administration"
  test "create", ~M[admin, conn, order, _part] do
    params = %{
      "order_id" => order.id,
      "name" => "Test Part"
    }

    conn =
      conn
      |> assign(:maintenance, MaintenanceParrot)
      |> admin_request(admin)
      |> post(Routes.api_maintenance_part_path(conn, :create, params))

    id = "#{params["order_id"]}"
    assert json_response(conn, 200) == %{}
    assert_receive {:create_part, %{"name" => "Test Part", "order_id" => ^id}}
  end

  @tag subdomain: "administration"
  test "update", ~M[admin, conn, _order, part] do
    params = %{
      "part" => %{
        "name" => "Great New Name"
      }
    }

    conn =
      conn
      |> assign(:maintenance, MaintenanceParrot)
      |> admin_request(admin)
      |> patch(Routes.api_maintenance_part_path(conn, :update, part.id), params)

    part_id = "#{part.id}"

    assert json_response(conn, 200) == %{}
    assert_receive {:update_part, ^part_id, %{"name" => "Great New Name"}}
  end

  @tag subdomain: "administration"
  test "delete", ~M[admin, conn, _order, part] do
    conn =
      conn
      |> assign(:maintenance, MaintenanceParrot)
      |> admin_request(admin)
      |> delete(Routes.api_maintenance_part_path(conn, :delete, part.id))

    id = "#{part.id}"
    assert json_response(conn, 200) == %{}
    assert_receive {:remove_part, ^id}
  end
end
