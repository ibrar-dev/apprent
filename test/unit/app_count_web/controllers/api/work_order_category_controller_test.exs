defmodule AppCountWeb.API.WorkOrderCategoryControllerTest do
  use AppCountWeb.ConnCase
  alias AppCount.Support.PropertyBuilder, as: PropBuilder

  defmodule MaintenanceParrot do
    use TestParrot

    parrot(:maintenance, :list_categories, [
      %{
        count: 112,
        id: 3329,
        name: "Leaking Pipe",
        third_party: false,
        visible: true
      }
    ])

    parrot(:maintenance, :create_category, "category created")
    parrot(:maintenance, :update_category, "category updated")
    parrot(:maintenance, :transfer, "category transfered")
    parrot(:maintenance, :delete_category, "category deleted")
  end

  setup do
    builder =
      PropBuilder.new(:create)
      |> PropBuilder.add_property()
      |> PropBuilder.add_super_admin()

    admin = PropBuilder.get_requirement(builder, :admin)

    ~M[admin]
  end

  @tag subdomain: "administration"
  test "index returns list of categories", ~M[admin, conn] do
    expected_list_of_categories = [
      %{
        "count" => 112,
        "id" => 3329,
        "name" => "Leaking Pipe",
        "third_party" => false,
        "visible" => true
      }
    ]

    conn =
      assign(conn, :maintenance, MaintenanceParrot)
      |> admin_request(admin)

    # When
    conn = get(conn, Routes.api_work_order_category_path(conn, :index))

    assert json_response(conn, 200) == expected_list_of_categories
    assert_receive :list_categories
  end

  @tag subdomain: "administration"
  test "create", ~M[admin, conn] do
    new_category = %{
      "category" => "Giant space lizards invading apartment and eating my bread"
    }

    conn =
      assign(conn, :maintenance, MaintenanceParrot)
      |> admin_request(admin)

    # When
    conn = post(conn, Routes.api_work_order_category_path(conn, :create), new_category)

    assert json_response(conn, 200) == %{}

    assert_receive {:create_category,
                    "Giant space lizards invading apartment and eating my bread"}
  end

  @tag subdomain: "administration"
  test "update", ~M[admin, conn] do
    params = %{
      "category" => "Oh no the space lizards have mutated into blobs & are staining my cornices",
      "id" => 234_780
    }

    id = params["id"] |> to_string()
    category_update = params["category"]

    conn =
      assign(conn, :maintenance, MaintenanceParrot)
      |> admin_request(admin)

    # When
    conn = patch(conn, Routes.api_work_order_category_path(conn, :update, params["id"]), params)

    assert json_response(conn, 200) == %{}
    assert_receive {:update_category, ^id, ^category_update}
  end

  @tag subdomain: "administration"
  test "update transfers id to new id", ~M[admin, conn] do
    params = %{
      "transfer" => 3480,
      "id" => 234_780
    }

    id = params["id"] |> to_string()
    new_id = params["transfer"]

    conn =
      assign(conn, :maintenance, MaintenanceParrot)
      |> admin_request(admin)

    # When
    conn = patch(conn, Routes.api_work_order_category_path(conn, :update, params["id"]), params)

    assert json_response(conn, 200) == %{}
    assert_receive {:transfer, ^id, ^new_id}
  end

  @tag subdomain: "administration"
  test "deletes by id", ~M[admin, conn] do
    params = %{
      "id" => 234_780
    }

    id = params["id"] |> to_string()

    conn =
      assign(conn, :maintenance, MaintenanceParrot)
      |> admin_request(admin)

    # When
    conn = delete(conn, Routes.api_work_order_category_path(conn, :delete, params["id"]))

    assert json_response(conn, 200) == %{}
    assert_receive {:delete_category, ^id}
  end
end
