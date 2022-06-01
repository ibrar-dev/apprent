defmodule AppCountWeb.Controllers.Api.V1.CategoryControllerTest do
  use AppCountWeb.ConnCase
  use AppCount.Case
  alias AppCount.Support.PropertyBuilder, as: PropBuilder

  setup do
    builder =
      PropBuilder.new(:create)
      |> PropBuilder.add_property()
      |> PropBuilder.add_factory_admin()

    admin = PropBuilder.get_requirement(builder, :admin)

    ~M[admin]
  end

  defmodule MaintenanceParrot do
    use TestParrot

    parrot(:maintenance, :v1_list_categories, [
      %{id: 14, name: "HVAC", parent: %{}},
      %{id: 32, name: "Plumbing", parent: %{}}
    ])
  end

  @tag subdomain: "administration"
  test "index", ~M[admin, conn] do
    params = %{}

    list_of_categories = [
      %{"id" => 14, "name" => "HVAC", "parent" => %{}},
      %{"id" => 32, "name" => "Plumbing", "parent" => %{}}
    ]

    conn =
      assign(conn, :maintenance, MaintenanceParrot)
      |> admin_api_request(admin)

    # When
    conn = get(conn, Routes.admin_api_v1_category_path(conn, :index, params))

    assert_receive :v1_list_categories
    assert json_response(conn, 200) == list_of_categories
  end
end
