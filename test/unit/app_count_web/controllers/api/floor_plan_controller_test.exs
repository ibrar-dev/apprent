defmodule AppCount.Controllers.API.FloorPlanControllerTest do
  use AppCountWeb.ConnCase
  alias AppCount.Properties.FloorPlan
  @moduletag :floor_plan_controller

  setup do
    property = insert(:property)
    {:ok, [property: property, admin: admin_with_access([property.id])]}
  end

  test "index", %{conn: conn, property: property, admin: admin} do
    insert(:floor_plan, property: property)

    result =
      conn
      |> admin_request(admin)
      |> get("https://administration.example.com/api/floor_plans")
      |> json_response(200)

    assert length(result) == 1
  end

  test "create", %{conn: conn, admin: admin, property: property} do
    params = %{
      "floor_plan" => %{
        "name" => "Dumb name",
        "property_id" => property.id,
        "feature_ids" => [insert(:feature).id]
      }
    }

    conn
    |> admin_request(admin)
    |> post("https://administration.example.com/api/floor_plans", params)
    |> json_response(200)

    assert Repo.get_by(FloorPlan, name: "Dumb name", property_id: property.id)
  end

  test "update", %{conn: conn, admin: admin} do
    floor_plan = insert(:floor_plan)

    params = %{
      "floor_plan" => %{
        "name" => "Updated Name"
      }
    }

    conn
    |> admin_request(admin)
    |> patch("https://administration.example.com/api/floor_plans/#{floor_plan.id}", params)
    |> json_response(200)

    assert Repo.get(FloorPlan, floor_plan.id).name == "Updated Name"
  end

  test "delete", %{conn: conn, admin: admin} do
    floor_plan = insert(:floor_plan)

    conn
    |> admin_request(admin)
    |> delete("https://administration.example.com/api/floor_plans/#{floor_plan.id}")
    |> json_response(200)

    refute Repo.get(FloorPlan, floor_plan.id)
  end
end
