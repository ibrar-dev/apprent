defmodule AppCountWeb.Controllers.Api.V1.TechControllerTest do
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

    parrot(:maintenance, :v1_list_techs, [
      %{id: 14, name: "Efrim Menuck", property_ids: [4]},
      %{id: 32, name: "Sir Archibald Von Reginald", property_ids: [188]}
    ])

    parrot(:maintenance, :v1_get_tech, %{
      id: 14,
      name: "Efrim Menuck",
      property_ids: [4]
    })

    parrot(:maintenance, :v1_update_tech, {:ok, %{}})
  end

  @tag subdomain: "administration"
  test "index for :min", ~M[admin, conn] do
    params = %{}

    list_of_techs = [
      %{"id" => 14, "name" => "Efrim Menuck", "property_ids" => [4]},
      %{"id" => 32, "name" => "Sir Archibald Von Reginald", "property_ids" => [188]}
    ]

    conn =
      assign(conn, :maintenance, MaintenanceParrot)
      |> admin_api_request(admin)

    # When
    conn = get(conn, Routes.admin_api_v1_tech_path(conn, :index, params))

    conn_admin = conn.assigns.admin

    assert_receive {:v1_list_techs,
                    %AppCount.Core.ClientSchema{
                      name: "dasmen",
                      attrs: ^conn_admin
                    }}

    assert json_response(conn, 200) == list_of_techs
  end

  @tag subdomain: "administration"
  test "show tech with id", ~M[admin, conn] do
    tech = %{"id" => 14, "name" => "Efrim Menuck", "property_ids" => [4]}

    conn =
      assign(conn, :maintenance, MaintenanceParrot)
      |> admin_api_request(admin)

    # When
    conn = get(conn, Routes.admin_api_v1_tech_path(conn, :show, 14))

    conn_admin = conn.assigns.admin

    assert_receive {:v1_get_tech,
                    %AppCount.Core.ClientSchema{
                      name: "dasmen",
                      attrs: ^conn_admin
                    }, "14"}

    assert json_response(conn, 200) == tech
  end

  @tag subdomain: "administration"
  test "update tech with id and attributes", ~M[admin, conn] do
    tech = %{"name" => "Efrim Menuck"}
    params = %{"tech" => tech}

    conn =
      assign(conn, :maintenance, MaintenanceParrot)
      |> admin_api_request(admin)

    # When
    conn = patch(conn, Routes.admin_api_v1_tech_path(conn, :update, 14), params)

    conn_admin = conn.assigns.admin

    assert_receive {:v1_update_tech,
                    %AppCount.Core.ClientSchema{
                      name: "dasmen",
                      attrs: ^conn_admin
                    }, "14", ^tech}

    assert json_response(conn, 200) == %{}
  end
end
