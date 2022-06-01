defmodule AppCountWeb.Controllers.API.PropertyControllerTest do
  use AppCountWeb.ConnCase
  alias AppCount.Properties.Property
  @moduletag :property_controller

  setup do
    property = insert(:property)
    admin = %{roles: ["Super Admin"], property_ids: [property.id]}
    {:ok, property: property, admin: admin}
  end

  test "index", %{conn: conn, admin: admin} do
    conn
    |> admin_request(admin)
    |> get("http://administration.example.com/api/properties")
    |> json_response(200)
    |> length
    |> Kernel.==(1)
    |> assert
  end

  test "min index", %{conn: conn, admin: admin} do
    conn
    |> admin_request(admin)
    |> get("http://administration.example.com/api/properties?min=true")
    |> json_response(200)
    |> length
    |> Kernel.==(1)
    |> assert
  end

  test "create", %{conn: conn, admin: admin} do
    params = %{
      "property" => %{
        "address" => %{
          "street" => "123 Sesame St",
          "city" => "Whatever",
          "state" => "CA",
          "zip" => "90210"
        },
        "code" => "code",
        "name" => "Sample Property"
      }
    }

    conn
    |> admin_request(admin)
    |> post("http://administration.example.com/api/properties", params)
    |> json_response(200)

    created_property = Repo.get_by(Property, name: "Sample Property", code: "code")

    assert created_property
  end

  test "show", %{conn: conn, admin: admin, property: property} do
    resp =
      conn
      |> admin_request(admin)
      |> get("http://administration.example.com/api/properties/#{property.id}")
      |> json_response(200)

    assert resp["id"] == property.id
  end

  test "update", %{conn: conn, admin: admin, property: property} do
    params = %{
      "property" => %{
        "code" => "some_new_code"
      }
    }

    conn
    |> admin_request(admin)
    |> patch("http://administration.example.com/api/properties/#{property.id}", params)
    |> json_response(200)

    assert Repo.get(Property, property.id).code == "some_new_code"
  end

  test "delete", %{conn: conn, admin: admin, property: property} do
    conn
    |> admin_request(admin)
    |> delete("http://administration.example.com/api/properties/#{property.id}")
    |> json_response(200)

    refute Repo.get_by(Property, name: property.name, code: property.code)
  end
end
