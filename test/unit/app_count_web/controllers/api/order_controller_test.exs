defmodule AppCountWeb.API.OrderControllerTest do
  use AppCountWeb.ConnCase
  alias AppCount.Support.PropertyBuilder, as: PropBuilder
  alias AppCount.Core.Clock
  alias AppCount.Core.ClientSchema

  def snapshot(name) do
    %{
      "completed" => 4,
      "created" => 7,
      "id" => 57899,
      "name" => name
    }
  end

  def assignment do
    %{
      "admin_id" => 578,
      "creator" => "Mack Daniels",
      "id" => 171_191,
      "status" => "on_hold",
      "tech" => "Gary Holloman",
      "tech_id" => 358
    }
  end

  def partial_order(id) do
    %{
      "category" => "Plumbing Washing Machine Issues",
      "id" => id,
      "status" => "cancelled",
      "unit" => "1218",
      "unit_id" => 40742
    }
  end

  defmodule MaintenanceParrot do
    use TestParrot
    defdelegate partial_order(id), to: AppCountWeb.API.OrderControllerTest
    defdelegate snapshot(name), to: AppCountWeb.API.OrderControllerTest
    defdelegate assignment, to: AppCountWeb.API.OrderControllerTest

    parrot(
      :maintenance,
      :list_orders_new,
      %{
        assigned: [
          %{
            assignments: [assignment()],
            category: "Other",
            category_id: 1664,
            entry_allowed: true,
            has_pet: false,
            id: 184_109
          }
        ]
      }
    )

    parrot(:maintenance, :list_orders_type, [partial_order(1234)])

    parrot(:maintenance, :get_tenants_orders, partial_order(4567))

    parrot(
      :maintenance,
      :show_order,
      %{
        "category" => partial_order(1113),
        "id" => 184_189,
        "property_id" => 193
      }
    )

    parrot(:maintenance, :create_order, {:ok, %{id: 107, ticket: "example ticket"}})

    parrot(
      :maintenance,
      :update_order,
      %{
        category: partial_order(5555),
        id: 44467,
        property_id: 193
      }
    )

    parrot(
      :maintenance,
      :delete_order,
      %{
        "category" => partial_order(543),
        "id" => 44467,
        "property_id" => 193
      }
    )

    parrot(:maintenance, :admin_daily_snapshot, snapshot("Summit Ridge"))

    parrot(:maintenance, :daily_snapshot, snapshot("Somerstone"))
  end

  setup do
    builder =
      PropBuilder.new(:create)
      |> PropBuilder.add_property()
      |> PropBuilder.add_factory_admin()

    property = PropBuilder.get_requirement(builder, :property)
    admin = PropBuilder.get_requirement(builder, :admin)
    ~M[admin,  property]
  end

  @tag subdomain: "administration"
  test "index retrieves new orders", ~M[admin, conn, property] do
    new_order = %{
      "assigned" => [
        %{
          "assignments" => [assignment()],
          "category" => "Other",
          "category_id" => 1664,
          "entry_allowed" => true,
          "has_pet" => false,
          "id" => 184_109
        }
      ]
    }

    params = %{
      "new" => "irrelvant stuff",
      "properties" => property.id,
      # nil given to list_orders_new obtains past 24h
      "dates" => nil
    }

    # schema = AppCount.Public.get_client_by_schema("dasmen").schema

    conn =
      assign(conn, :maintenance, MaintenanceParrot)
      |> admin_request(admin)

    # When
    conn = get(conn, Routes.api_order_path(conn, :index, params))

    conn_admin = conn.assigns.admin

    property_id = property.id
    dates = ""

    assert json_response(conn, 200) ==
             new_order

    assert_receive {:list_orders_new, ^conn_admin, ^dates,
                    %AppCount.Core.ClientSchema{attrs: [^property_id], name: "dasmen"}}
  end

  @tag subdomain: "administration"
  test "index retrives orders by type", ~M[admin, conn, property] do
    cancelled_order = [partial_order(1234)]

    params = %{
      "type" => "cancelled",
      "property_id" => property.id
    }

    property_id =
      property.id
      |> to_string()

    wrapped_property_id = AppCount.Core.ClientSchema.new("dasmen", property_id)

    order_type = params["type"]

    conn =
      assign(conn, :maintenance, MaintenanceParrot)
      |> admin_request(admin)

    # When
    conn = get(conn, Routes.api_order_path(conn, :index, params))

    assert json_response(conn, 200) == cancelled_order
    assert_receive {:list_orders_type, ^wrapped_property_id, ^order_type}
  end

  @tag subdomain: "administration"
  test "show retrives tenant orders by order id", ~M[admin, conn] do
    tenant_order = partial_order(4567)

    params = %{
      "id" => 176_743,
      "tenantsOrders" => "irrelevant"
    }

    id =
      params["id"]
      |> to_string()

    conn =
      assign(conn, :maintenance, MaintenanceParrot)
      |> admin_request(admin)

    # When
    conn = get(conn, Routes.api_order_path(conn, :show, params["id"]), params)

    assert json_response(conn, 200) == tenant_order
    assert_receive {:get_tenants_orders, %AppCount.Core.ClientSchema{attrs: ^id, name: "dasmen"}}
  end

  @tag subdomain: "administration"
  test "show retrives orders by order id", ~M[admin, conn] do
    order = %{
      "category" => partial_order(1113),
      "id" => 184_189,
      "property_id" => 193
    }

    params = %{
      "id" => 184_189,
      "new" => "irrelevant"
    }

    conn =
      assign(conn, :maintenance, MaintenanceParrot)
      |> admin_request(admin)

    # When
    conn = get(conn, Routes.api_order_path(conn, :show, params["id"]), params)

    id =
      params["id"]
      |> to_string()

    conn_admin = conn.assigns.admin

    assert json_response(conn, 200) == order

    assert_receive {:show_order,
                    %AppCount.Core.ClientSchema{
                      name: "dasmen",
                      attrs: ^conn_admin
                    }, ^id}
  end

  @tag subdomain: "administration"
  test "create when it is successful", ~M[admin, conn] do
    params = %{
      "workOrder" => %{
        "category_id" => insert(:category).id,
        "property_id" => insert(:property).id,
        "ticket" => "example ticket"
      }
    }

    conn =
      assign(conn, :maintenance, MaintenanceParrot)
      |> admin_request(admin)

    # When
    conn = post(conn, Routes.api_order_path(conn, :create), params)
    response = json_response(conn, 200)["order_data"]

    assert is_binary(response["ticket"])
    assert is_integer(response["id"])
  end

  @tag subdomain: "administration"
  test "create when it is NOT successful", ~M[admin, conn] do
    params = %{
      "workOrder" => %{
        "ticket" => "example ticket"
      }
    }

    conn = admin_request(conn, admin)

    # When
    conn = post(conn, Routes.api_order_path(conn, :create), params)

    assert json_response(conn, 422) == "Property can't be blank,Category can't be blank"
  end

  @tag subdomain: "administration"
  test "update amends with work order and returns empty map", ~M[admin, conn] do
    wrapped_work_order =
      ClientSchema.new(
        "dasmen",
        "do x and not y, handy-people"
      )

    params = %{"id" => 667, "workOrder" => "do x and not y, handy-people"}

    id = "667"

    conn =
      assign(conn, :maintenance, MaintenanceParrot)
      |> admin_request(admin)

    # When
    conn = patch(conn, Routes.api_order_path(conn, :update, params["id"]), params)

    assert json_response(conn, 200) == %{}
    assert_receive {:update_order, ^id, ^wrapped_work_order}
  end

  @tag subdomain: "administration"
  test "update soft deletes work order and returns empty map", ~M[admin, conn] do
    params = %{"id" => 766, "reason" => "Tech did lefty-tighty, righty-loosey"}

    id =
      params["id"]
      |> to_string()

    reason_for_deletion =
      params["reason"]
      |> to_string()

    conn =
      assign(conn, :maintenance, MaintenanceParrot)
      |> admin_request(admin)

    # When
    conn = patch(conn, Routes.api_order_path(conn, :delete, params["id"]), params)

    admin_name = conn.assigns.admin.name

    assert json_response(conn, 200) == %{}
    assert_receive {:delete_order, ^admin_name, ^id, ^reason_for_deletion}
  end

  @tag subdomain: "administration"
  test "snapshot works with one date", ~M[admin, conn] do
    current_date_time = Clock.now()

    params = %{
      "snapshot" => "#{current_date_time}"
    }

    conn =
      assign(conn, :maintenance, MaintenanceParrot)
      |> admin_request(admin)

    # When
    conn = post(conn, Routes.api_order_path(conn, :create), params)

    expected_response = snapshot("Summit Ridge")

    conn_admin = conn.assigns.admin

    assert json_response(conn, 200) == expected_response
    assert_receive {:admin_daily_snapshot, ^conn_admin, ^current_date_time}
  end

  @tag subdomain: "administration"
  test "snapshot works with 2 dates", ~M[admin, conn] do
    current_date_time = Clock.now()
    two_days_ago = Clock.now({-2, :days})

    params = %{
      "snapshot" => %{
        "end_date" => "#{current_date_time}",
        "start_date" => "#{two_days_ago}"
      }
    }

    conn =
      assign(conn, :maintenance, MaintenanceParrot)
      |> admin_request(admin)

    # When
    conn = post(conn, Routes.api_order_path(conn, :create), params)

    expected_response = %{
      "completed" => 4,
      "created" => 7,
      "id" => 57899,
      "name" => "Somerstone"
    }

    conn_admin = conn.assigns.admin

    assert json_response(conn, 200) == expected_response
    assert_receive {:daily_snapshot, ^conn_admin, ^two_days_ago, ^current_date_time}
  end
end
