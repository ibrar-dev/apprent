defmodule AppCountWeb.Controllers.API.FeatureControllerTest do
  use AppCountWeb.ConnCase
  alias AppCount.Properties.Feature
  alias AppCount.Properties.UnitFeature
  @moduletag :feature_controller

  setup do
    property = insert(:property)
    unit = insert(:unit, property: property)
    feature = insert(:feature, property: property)
    admin = %{property_ids: [property.id], client_schema: "dasmen", roles: ["Super Admin"]}

    {
      :ok,
      admin: admin, feature: feature, unit: unit, property: property
    }
  end

  test "index", %{conn: conn, admin: admin, feature: feature} do
    resp =
      conn
      |> admin_request(admin)
      |> get("https://administration.example.com/api/features")
      |> json_response(200)

    assert length(resp) == 1
    assert hd(resp)["id"] == feature.id
    assert hd(resp)["price"] == "#{Decimal.to_integer(feature.price)}"
  end

  test "create", %{conn: conn, admin: admin, property: property} do
    params = %{
      "feature" => %{
        "property_id" => property.id,
        "price" => 250,
        "name" => "Pool View"
      }
    }

    conn
    |> admin_request(admin)
    |> post("https://administration.example.com/api/features", params)
    |> json_response(200)

    Repo.get_by(Feature, property_id: property.id, name: "Pool View")
    |> Map.get(:price)
    |> Decimal.to_integer()
    |> Kernel.==(250)
    |> assert
  end

  test "update", %{conn: conn, admin: admin, feature: feature, unit: unit} do
    new_params = %{
      "feature" => %{
        "name" => "Cool Pool View",
        "unit_ids" => [unit.id]
      }
    }

    conn
    |> admin_request(admin)
    |> patch("https://administration.example.com/api/features/#{feature.id}", new_params)
    |> json_response(200)

    assert Repo.get(Feature, feature.id, prefix: "dasmen").name == "Cool Pool View"
    assert Repo.get_by(UnitFeature, [feature_id: feature.id, unit_id: unit.id], prefix: "dasmen")
  end

  test "delete", %{conn: conn, admin: admin, feature: feature} do
    conn
    |> admin_request(admin)
    |> delete("https://administration.example.com/api/features/#{feature.id}")
    |> json_response(200)

    refute Repo.get(Feature, feature.id, prefix: "dasmen")
  end
end
