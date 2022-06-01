defmodule AppCountWeb.Controllers.API.VisitControllerTest do
  use AppCountWeb.ConnCase
  alias AppCount.Properties.Visit
  @moduletag :visit_controller

  setup do
    property = insert(:property)
    unit = insert(:unit, property: property)
    tenant = insert(:tenant)

    {
      :ok,
      lease: insert(:lease, tenants: [tenant], unit: unit),
      admin: admin_with_access([property.id]),
      tenant: tenant,
      unit: unit,
      visit: insert(:visit, property: property, tenant: tenant),
      property: property
    }
  end

  test "index", %{conn: conn, admin: admin, visit: visit} do
    resp =
      conn
      |> admin_request(admin)
      |> get("https://administration.example.com/api/visits")
      |> json_response(200)

    assert length(resp) == 1
    assert hd(resp)["id"] == visit.id
  end

  test "create", %{conn: conn, admin: admin, tenant: tenant, property: property} do
    desc = "Came to rip some paper towels"

    params = %{
      "visit" => %{
        "tenant_id" => tenant.id,
        "property_id" => property.id,
        "description" => desc
      }
    }

    conn
    |> admin_request(admin)
    |> post("https://administration.example.com/api/visits", params)
    |> json_response(200)

    assert Repo.get_by(Visit, property_id: property.id, tenant_id: tenant.id, description: desc)
  end

  test "create with_delinquency", %{conn: conn, admin: admin, tenant: tenant, property: property} do
    desc = "Created Delinquency visit memo"

    params = %{
      "visit" => %{
        "tenant_id" => tenant.id,
        "property_id" => property.id,
        "description" => desc,
        "delinquency" => DateTime.utc_now()
      }
    }

    conn
    |> admin_request(admin)
    |> post("https://administration.example.com/api/visits", params)
    |> json_response(200)

    visit = Repo.get_by(Visit, property_id: property.id, tenant_id: tenant.id, description: desc)

    assert visit
    assert visit.delinquency
  end

  test "delete", %{conn: conn, admin: admin, visit: visit} do
    conn
    |> admin_request(admin)
    |> delete("https://administration.example.com/api/visits/#{visit.id}")
    |> json_response(200)

    refute Repo.get(Visit, visit.id)
  end
end
