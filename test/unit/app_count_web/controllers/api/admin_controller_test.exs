defmodule AppCountWeb.Controllers.API.AdminControllerTest do
  use AppCountWeb.ConnCase
  alias AppCount.Support.PropertyBuilder, as: PropBuilder
  alias AppCount.Admins.Admin

  defmodule AdminsParrot do
    use TestParrot

    parrot(
      :admins,
      :update_admin,
      {:ok, %{updated_admin_params: %{username: "cool_admin_mcgee"}}}
    )

    parrot(:admins, :list_tech_admins, [%{tech_name: "tech n9ne"}])

    parrot(:admins, :list_admins, [
      %{
        admin: "admin #1"
      },
      %{
        admin: "admin #2"
      }
    ])

    parrot(:admins, :get_admin!, [
      %{admin: "admin #1"}
    ])

    parrot(:admins, :create_admin, {:ok, %Admin{username: "other admin person"}})

    parrot(:admins, :delete_admin, %{})

    parrot(:admins, :bounce_admin_email, {:ok, %{bounce: true}})
  end

  setup do
    builder =
      PropBuilder.new(:create)
      |> PropBuilder.add_property()
      |> PropBuilder.add_super_admin()

    superadmin = PropBuilder.get_requirement(builder, :admin)
    ~M[superadmin]
  end

  @tag subdomain: "administration"
  test "index gets list of techs", ~M[superadmin, conn] do
    params = %{"fetchTechs" => "irrelevant value"}
    list_of_techs = [%{"tech_name" => "tech n9ne"}]

    conn =
      assign(conn, :admins, AdminsParrot)
      |> admin_request(superadmin)

    # when
    conn = get(conn, Routes.api_admin_path(conn, :index), params)

    conn_admin = conn.assigns.admin

    assert json_response(conn, 200) == list_of_techs

    assert_receive {:list_tech_admins,
                    %AppCount.Core.ClientSchema{
                      name: "dasmen",
                      attrs: ^conn_admin
                    }}
  end

  @tag subdomain: "administration"
  test "get admin by id", ~M[superadmin, conn] do
    params = %{id: 0}

    conn =
      assign(conn, :admins, AdminsParrot)
      |> admin_request(superadmin)
      |> get(Routes.api_admin_path(conn, :show, 0), params)

    schema = conn.assigns.client_schema
    assert json_response(conn, 200) == [%{"admin" => "admin #1"}]
    assert_receive {:get_admin!, %AppCount.Core.ClientSchema{attrs: "0", name: ^schema}}
  end

  @tag subdomain: "administration"
  test "create admin", ~M[superadmin, conn] do
    params = %{
      id: 7237,
      admin: %{"username" => "other admin person"}
    }

    conn =
      assign(conn, :admins, AdminsParrot)
      |> admin_request(superadmin)
      |> post(Routes.api_admin_path(conn, :create), params)

    expected_response = %{
      "aggregate" => false,
      "email" => nil,
      "id" => nil,
      "inserted_at" => nil,
      "name" => nil,
      "password" => nil,
      "password_hash" => nil,
      "permissions" => [],
      "profile" => nil,
      "prospects" => [],
      "regions" => [],
      "reset_pw" => nil,
      "roles" => nil,
      "updated_at" => nil,
      "username" => "other admin person",
      "uuid" => nil,
      "active" => true,
      "email_subscriptions" => [],
      "admin_roles" => [],
      "custom_roles" => [],
      "is_super_admin" => nil,
      "public_user" => nil,
      "public_user_id" => nil
    }

    received_admin = params.admin

    schema = conn.assigns.client_schema

    assert json_response(conn, 200) == expected_response

    assert_receive {:create_admin,
                    %AppCount.Core.ClientSchema{attrs: ^received_admin, name: ^schema}}
  end

  @tag subdomain: "administration"
  test "delete admin by id", ~M[superadmin, conn] do
    params = %{id: 212_121}

    conn =
      assign(conn, :admins, AdminsParrot)
      |> admin_request(superadmin)
      |> delete(Routes.api_admin_path(conn, :delete, 212_121), params)

    schema = conn.assigns.client_schema

    received_admin = conn.assigns.admin
    assert json_response(conn, 200) == %{"success" => true}

    assert_receive {:delete_admin, ^received_admin,
                    %AppCount.Core.ClientSchema{attrs: "212121", name: ^schema}}
  end

  @tag subdomain: "administration"
  test "index gets list of admins with params attached", ~M[superadmin, conn] do
    params = %{"fetchEmployees" => "irrelevant value"}
    list_of_admins = [%{"admin" => "admin #1"}, %{"admin" => "admin #2"}]

    conn =
      assign(conn, :admins, AdminsParrot)
      |> admin_request(superadmin)

    # when
    conn = get(conn, Routes.api_admin_path(conn, :index), params)

    conn_admin = conn.assigns.admin

    schema = conn.assigns.client_schema

    assert json_response(conn, 200) == list_of_admins
    assert_receive {:list_admins, %AppCount.Core.ClientSchema{attrs: ^conn_admin, name: ^schema}}
  end

  @tag subdomain: "administration"
  test "index gets list of admins", ~M[superadmin, conn] do
    list_of_admins = [%{"admin" => "admin #1"}, %{"admin" => "admin #2"}]

    conn =
      assign(conn, :admins, AdminsParrot)
      |> admin_request(superadmin)

    # when
    conn = get(conn, Routes.api_admin_path(conn, :index))

    schema = conn.assigns.client_schema

    assert json_response(conn, 200) == list_of_admins
    assert_receive {:list_admins, %AppCount.Core.ClientSchema{attrs: nil, name: ^schema}}
  end

  @tag subdomain: "administration"
  test "update works successfully", ~M[superadmin,conn] do
    params = %{
      id: 73482,
      admin: %{
        username: "cool_admin_mcgee"
      }
    }

    conn =
      assign(conn, :admins, AdminsParrot)
      |> admin_request(superadmin)

    # when
    conn = patch(conn, Routes.api_admin_path(conn, :update, params.id), params)

    schema = conn.assigns.client_schema

    params_to_update = %{"username" => "cool_admin_mcgee"}
    received_id = params.id |> to_string()

    assert json_response(conn, 200) ==
             %{"updated_admin_params" => params_to_update}

    assert_receive {:update_admin, ^received_id,
                    %AppCount.Core.ClientSchema{attrs: ^params_to_update, name: ^schema}}
  end

  @tag subdomain: "administration"
  test "update works successfully when deactivating an admin", ~M[superadmin,conn] do
    AdminsParrot.say_update_admin({:ok, %{updated_admin_params: %{active: false}}})

    activity_status = false

    params = %{
      id: 390,
      admin: %{
        active: activity_status,
        bounce: not activity_status
      }
    }

    conn =
      assign(conn, :admins, AdminsParrot)
      |> admin_request(superadmin)

    # when
    conn = patch(conn, Routes.api_admin_path(conn, :update, params.id), params)

    schema = conn.assigns.client_schema

    params_to_update = %{"active" => activity_status}
    received_id = params.id |> to_string()

    assert json_response(conn, 200) == %{"updated_admin_params" => params_to_update}

    assert_receive {:update_admin, ^received_id,
                    %AppCount.Core.ClientSchema{attrs: %{active: ^activity_status}, name: ^schema}}

    assert_receive {:bounce_admin_email, ^received_id, true}
  end
end
