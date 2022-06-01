defmodule AppCountWeb.Controllers.API.TenantControllerTest do
  use AppCountWeb.ConnCase
  alias AppCount.Support.PropertyBuilder, as: PropBuilder

  defmodule TenantParrot do
    use TestParrot

    parrot(:tenant_boundary, :get_residents_by_type, %{
      id: 983_214,
      name: "Lewis Hamilton",
      type: "current",
      unit: "1922"
    })

    parrot(:tenant_boundary, :list_tenants_min, [
      %{
        name: "Sebastian Vettel",
        id: 5,
        lease: "lease info"
      },
      %{
        name: "Kimi Raikkonen",
        id: 7,
        lease: "you will not have the drink"
      }
    ])

    parrot(:tenant_boundary, :navbar_search, %{
      id: 16,
      name: "Charles Leclerc",
      property: "Monaco"
    })

    parrot(:tenant_boundary, :tenant_search, %{
      id: 3,
      name: "Daniel Ricciardo",
      unit: "101AB"
    })

    parrot(:tenant_boundary, :list_tenants_balance, %{
      name: "Michael Schumacher",
      balance: 55_000_123,
      id: 32
    })

    parrot(:tenant_boundary, :list_tenants, [
      %{
        name: "Mika Hakkinen",
        id: 14,
        lease: "lease info"
      },
      %{
        name: "Valtteri Bottas",
        id: 77,
        lease: "lease info"
      }
    ])

    parrot(:tenant_boundary, :create_tenant, {:ok, "tenant created"})

    parrot(:tenant_boundary, :create_new_tenant, {:ok, "tenant created"})

    parrot(:tenant_boundary, :get_tenant, %{
      "name" => "Niki Lauda",
      "id" => 12
    })

    parrot(:tenant_boundary, :sync_external_id, {:ok, %{external_id: 12}})

    parrot(:tenant_boundary, :update_tenant, "tenant updated")
  end

  setup do
    builder =
      PropBuilder.new(:create)
      |> PropBuilder.add_property()
      |> PropBuilder.add_admin()
      |> PropBuilder.add_tenant()

    admin = PropBuilder.get_requirement(builder, :admin)
    property = PropBuilder.get_requirement(builder, :property)
    tenant = PropBuilder.get_requirement(builder, :tenant)

    ~M[admin, tenant, property]
  end

  @tag subdomain: "administration"
  test "index obtains by lease type", ~M[admin, conn] do
    params = %{"property_id" => "70", "type" => "current"}
    property_id = params["property_id"]
    lease_type = params["type"]

    expected_response = %{
      "id" => 983_214,
      "name" => "Lewis Hamilton",
      "type" => "current",
      "unit" => "1922"
    }

    conn =
      assign(conn, :tenant_boundary, TenantParrot)
      |> admin_request(admin)

    conn = get(conn, Routes.api_tenant_path(conn, :index), params)

    conn_admin = conn.assigns.admin

    assert json_response(conn, 200) == expected_response
    assert_receive {:get_residents_by_type, ^conn_admin, ^property_id, ^lease_type}
  end

  @tag subdomain: "administration"
  test "index obtains by list of tenants for an admin", ~M[admin, conn] do
    params = %{"min" => "irrelevant info"}

    expected_response = [
      %{
        "name" => "Sebastian Vettel",
        "id" => 5,
        "lease" => "lease info"
      },
      %{
        "name" => "Kimi Raikkonen",
        "id" => 7,
        "lease" => "you will not have the drink"
      }
    ]

    conn =
      assign(conn, :tenant_boundary, TenantParrot)
      |> admin_request(admin)

    conn = get(conn, Routes.api_tenant_path(conn, :index), params)

    conn_admin = conn.assigns.admin

    assert json_response(conn, 200) == expected_response
    assert_receive {:list_tenants_min, ^conn_admin}
  end

  @tag subdomain: "administration"
  test "index searches by name and property", ~M[admin, conn] do
    params = %{"search" => "Leclerc", "property_id" => "554"}
    name_searched = params["search"]
    property_id = params["property_id"]

    expected_response = %{
      "id" => 3,
      "name" => "Daniel Ricciardo",
      "unit" => "101AB"
    }

    conn =
      assign(conn, :tenant_boundary, TenantParrot)
      |> admin_request(admin)

    conn = get(conn, Routes.api_tenant_path(conn, :index), params)

    conn_admin = conn.assigns.admin

    assert json_response(conn, 200) == expected_response
    assert_receive {:tenant_search, ^conn_admin, ^name_searched, ^property_id}
  end

  @tag subdomain: "administration"
  test "index searches by name", ~M[admin, conn] do
    params = %{"search" => "Leclerc"}
    name_searched = "Leclerc"

    expected_response = %{
      "id" => 16,
      "name" => "Charles Leclerc",
      "property" => "Monaco"
    }

    conn =
      assign(conn, :tenant_boundary, TenantParrot)
      |> admin_request(admin)

    conn = get(conn, Routes.api_tenant_path(conn, :index), params)

    conn_admin = conn.assigns.admin

    assert json_response(conn, 200) == expected_response
    assert_receive {:navbar_search, ^conn_admin, ^name_searched}
  end

  @tag subdomain: "administration"
  test "index obtains tenant balance", ~M[admin, conn] do
    params = %{"with_bal" => "irrelevant", "property_id" => "279"}
    property_id = params["property_id"]

    expected_response = %{
      "name" => "Michael Schumacher",
      "balance" => 55_000_123,
      "id" => 32
    }

    conn =
      assign(conn, :tenant_boundary, TenantParrot)
      |> admin_request(admin)

    conn = get(conn, Routes.api_tenant_path(conn, :index), params)

    assert json_response(conn, 200) == expected_response
    assert_receive {:list_tenants_balance, ^property_id}
  end

  @tag subdomain: "administration"
  test "index obtains list of tenants for a property", ~M[admin, conn] do
    params = %{"property_id" => "345890"}
    property_id = params["property_id"]

    expected_response = [
      %{"id" => 14, "lease" => "lease info", "name" => "Mika Hakkinen"},
      %{"id" => 77, "lease" => "lease info", "name" => "Valtteri Bottas"}
    ]

    conn =
      assign(conn, :tenant_boundary, TenantParrot)
      |> admin_request(admin)

    conn = get(conn, Routes.api_tenant_path(conn, :index), params)

    conn_admin = conn.assigns.admin

    assert json_response(conn, 200) == expected_response
    assert_receive {:list_tenants, ^conn_admin, ^property_id}
  end

  @tag subdomain: "administration"
  test "index obtains list of all tenants", ~M[admin, conn] do
    expected_response = [
      %{"id" => 14, "lease" => "lease info", "name" => "Mika Hakkinen"},
      %{"id" => 77, "lease" => "lease info", "name" => "Valtteri Bottas"}
    ]

    conn =
      assign(conn, :tenant_boundary, TenantParrot)
      |> admin_request(admin)

    conn = get(conn, Routes.api_tenant_path(conn, :index))
    conn_admin = conn.assigns.admin

    assert json_response(conn, 200) == expected_response
    assert_receive {:list_tenants, ^conn_admin}
  end

  @tag subdomain: "administration"
  test "create w/ lease id", ~M[admin, conn] do
    params = %{
      "tenant" => %{
        "name" => "Niki Lauda",
        "id" => 12
      },
      "lease_id" => 289
    }

    tenant = params["tenant"]
    lease_id = params["lease_id"]

    conn =
      assign(conn, :tenant_boundary, TenantParrot)
      |> admin_request(admin)

    conn = post(conn, Routes.api_tenant_path(conn, :create), params)
    conn_admin = conn.assigns.admin

    sent_params =
      tenant
      |> Map.put("admin", conn_admin)

    assert json_response(conn, 200) == %{}
    assert_receive {:create_tenant, ^sent_params, [lease_id: ^lease_id]}
  end

  @tag subdomain: "administration"
  test "create w/o lease id", ~M[admin, conn] do
    params = %{
      "tenant" => %{
        "name" => "Niki Lauda",
        "id" => 12
      }
    }

    tenant = params["tenant"]

    conn =
      assign(conn, :tenant_boundary, TenantParrot)
      |> admin_request(admin)

    conn = post(conn, Routes.api_tenant_path(conn, :create), params)
    conn_admin_name = conn.assigns.admin.name

    sent_params =
      tenant
      |> Map.put("admin", conn_admin_name)

    assert json_response(conn, 200) == %{}
    assert_receive {:create_tenant, ^sent_params}
  end

  @tag subdomain: "administration"
  test "create new tenant", ~M[admin, conn] do
    params = %{
      "tenant" => %{
        "name" => "Niki Lauda",
        "id" => 12
      },
      "create_new" => "irrelevant"
    }

    tenant = params["tenant"]

    conn =
      assign(conn, :tenant_boundary, TenantParrot)
      |> admin_request(admin)

    conn = post(conn, Routes.api_tenant_path(conn, :create), params)
    conn_admin_name = conn.assigns.admin.name

    sent_params =
      tenant
      |> Map.put("admin", conn_admin_name)

    assert json_response(conn, 200) == %{}
    assert_receive {:create_new_tenant, ^sent_params}
  end

  @tag subdomain: "administration"
  test "successfully get tenant by ID", ~M[admin, conn] do
    params = %{"id" => "12"}
    tenant_id = params["id"]

    expected_response = %{"id" => 12, "name" => "Niki Lauda"}

    conn =
      assign(conn, :tenant_boundary, TenantParrot)
      |> admin_request(admin)

    conn = get(conn, Routes.api_tenant_path(conn, :show, params["id"]), params)

    conn_admin = conn.assigns.admin

    assert json_response(conn, 200) == expected_response
    assert_receive {:get_tenant, ^conn_admin, ^tenant_id}
  end

  @tag subdomain: "administration"
  test "successfully sync external ID", ~M[admin, conn] do
    params = %{"id" => 12, "sync" => "irrelevant"}
    tenant_id = params["id"] |> to_string()

    expected_response = %{"success" => params["id"]}

    conn =
      assign(conn, :tenant_boundary, TenantParrot)
      |> admin_request(admin)

    conn = patch(conn, Routes.api_tenant_path(conn, :update, params["id"]), params)

    assert json_response(conn, 200) == expected_response
    assert_receive {:sync_external_id, ^tenant_id}
  end

  @tag subdomain: "administration"
  test "unsuccessfully sync external ID", ~M[admin, conn] do
    TenantParrot.say_sync_external_id({:error, "error message"})

    params = %{"id" => 12, "sync" => "irrelevant"}
    tenant_id = params["id"] |> to_string()

    expected_response = %{"error" => "error message"}

    conn =
      assign(conn, :tenant_boundary, TenantParrot)
      |> admin_request(admin)

    conn = patch(conn, Routes.api_tenant_path(conn, :update, params["id"]), params)

    assert json_response(conn, 200) == expected_response
    assert_receive {:sync_external_id, ^tenant_id}
  end

  @tag subdomain: "administration"
  test "update tenant by ID", ~M[admin, conn] do
    params = %{
      "id" => 7,
      "tenant" => %{
        "name" => "Kimi Raikkonen",
        "lease" => "Leave me alone, I know what to do"
      }
    }

    tenant_id = params["id"] |> to_string()
    updated_tenant_info = params["tenant"]

    conn =
      assign(conn, :tenant_boundary, TenantParrot)
      |> admin_request(admin)

    conn = patch(conn, Routes.api_tenant_path(conn, :update, params["id"]), params)

    assert json_response(conn, 200) == %{}
    assert_receive {:update_tenant, ^tenant_id, ^updated_tenant_info}
  end

  test "clear_bounces", ~M[admin, conn] do
    conn =
      conn
      |> admin_request(admin)

    # For some reason this will not work with the route helper, gives route not found error
    conn = post(conn, "https://administration.example.com/api/tenants/8938/clear_bounces", %{})
    assert json_response(conn, 200) == %{}
  end
end
