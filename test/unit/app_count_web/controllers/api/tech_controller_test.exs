defmodule AppCountWeb.Controllers.Api.TechControllerTest do
  use AppCountWeb.ConnCase
  use AppCount.Case
  alias AppCount.Support.PropertyBuilder, as: PropBuilder
  alias Ecto.Changeset

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

    parrot(:maintenance, :list_techs, [
      %{id: 14, name: "Efrim Menuck", property_ids: [4]},
      %{id: 32, name: "Sir Archibald Von Reginald", property_ids: [188]}
    ])

    parrot(:maintenance, :create_tech, {:ok, %{this_parrot: "is sadly not relevant here"}})
    parrot(:maintenance, :set_all_categories, {:ok, %{some_weird: "skill map"}})
    parrot(:maintenance, :set_pass_code, %{more_irrelvant: "maps"})
    parrot(:maintenance, :update_tech, %{more_irrelvant: "maps"})
    parrot(:maintenance, :delete_tech, %{more_irrelvant: "maps"})
  end

  @tag subdomain: "administration"
  test "index for :min", ~M[admin, conn] do
    params = %{
      "min" => "irrelevant content"
    }

    list_of_techs = [
      %{"id" => 14, "name" => "Efrim Menuck", "property_ids" => [4]},
      %{"id" => 32, "name" => "Sir Archibald Von Reginald", "property_ids" => [188]}
    ]

    conn =
      assign(conn, :maintenance, MaintenanceParrot)
      |> admin_request(admin)

    # When
    conn = get(conn, Routes.api_tech_path(conn, :index, params))

    conn_admin = conn.assigns.admin

    assert_receive {:list_techs,
                    %AppCount.Core.ClientSchema{
                      name: "dasmen",
                      attrs: ^conn_admin
                    }, :min}

    assert json_response(conn, 200) == list_of_techs
  end

  describe "create" do
    @tag subdomain: "administration"
    test "create", ~M[admin, conn] do
      MaintenanceParrot.say_create_tech(
        {:error,
         Changeset.change(%AppCount.Maintenance.Tech{}, %{name: "Napoleon"})
         |> Changeset.add_error(:name, "A tech named Napoleon already exists")}
      )

      tech_attrs = %{
        name: "Odd Nosdam",
        email: "fake_email@email.com",
        phone: "555-123-4567"
      }

      tech_name = tech_attrs.name
      email = tech_attrs.email
      phone = tech_attrs.phone

      params = %{
        "tech" => tech_attrs
      }

      conn =
        assign(conn, :maintenance, MaintenanceParrot)
        |> admin_request(admin)

      # When
      conn = post(conn, Routes.api_tech_path(conn, :create, params))

      assert json_response(conn, 400) == %{
               "errors" => %{"name" => ["A tech named Napoleon already exists"]}
             }

      assert_receive {:create_tech,
                      %{
                        "email" => ^email,
                        "name" => ^tech_name,
                        "phone" => ^phone
                      }}
    end
  end

  @tag subdomain: "administration"
  test "updates and sets all tech categories", ~M[admin, conn] do
    params = %{
      "id" => 31,
      "all_categories" => "irrelevant"
    }

    tech_id = "#{params["id"]}"
    wrapped_tech_id = AppCount.Core.ClientSchema.new("dasmen", tech_id)

    conn =
      assign(conn, :maintenance, MaintenanceParrot)
      |> admin_request(admin)

    # When
    conn = patch(conn, Routes.api_tech_path(conn, :update, params["id"]), params)

    assert json_response(conn, 200) == %{}
    assert_receive {:set_all_categories, ^wrapped_tech_id}
  end

  @tag subdomain: "administration"
  test "updates and sets passcode", ~M[admin, conn] do
    params = %{
      "id" => 33,
      "pass_code" => "irrelevant"
    }

    tech_id = "#{params["id"]}"

    conn =
      assign(conn, :maintenance, MaintenanceParrot)
      |> admin_request(admin)

    # When
    conn = patch(conn, Routes.api_tech_path(conn, :update, params["id"]), params)

    assert json_response(conn, 200) == %{}
    assert_receive {:set_pass_code, ^tech_id}
  end

  @tag subdomain: "administration"
  test "updates tech attributes", ~M[admin, conn] do
    tech_attrs = %{
      name: "Odd Nosdam",
      email: "fake_email@email.com",
      phone: "555-123-4567",
      id: 37
    }

    tech_name = tech_attrs.name
    email = tech_attrs.email
    phone = tech_attrs.phone
    id = tech_attrs.id

    params = %{
      "tech" => tech_attrs
    }

    tech_id = "#{params["tech"].id}"
    wrapped_tech_id = AppCount.Core.ClientSchema.new("dasmen", tech_id)

    conn =
      assign(conn, :maintenance, MaintenanceParrot)
      |> admin_request(admin)

    # When
    conn = patch(conn, Routes.api_tech_path(conn, :update, tech_attrs.id), params)

    assert json_response(conn, 200) == %{}

    assert_receive {:update_tech, ^wrapped_tech_id,
                    %{
                      "email" => ^email,
                      "id" => ^id,
                      "name" => ^tech_name,
                      "phone" => ^phone
                    }}
  end

  @tag subdomain: "administration"
  test "deletes tech", ~M[admin, conn] do
    params = %{
      "id" => 39
    }

    tech_id = "#{params["id"]}"

    conn =
      assign(conn, :maintenance, MaintenanceParrot)
      |> admin_request(admin)

    # When
    conn = delete(conn, Routes.api_tech_path(conn, :update, params["id"]), params)

    assert json_response(conn, 200) == %{}
    assert_receive {:delete_tech, ^tech_id}
  end
end
