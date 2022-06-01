defmodule AppCount.Controllers.API.PropertyListControllerTest do
  use AppCountWeb.ConnCase
  alias AppCount.Support.HTTPClient
  @moduletag :property_list_controller

  setup do
    response = File.read!(Path.expand("../../../resources/authorize/token_response.xml", __DIR__))
    HTTPClient.initialize([response, response])
    on_exit(fn -> HTTPClient.stop() end)

    {:ok, _, property} =
      insert(:property)
      |> AppCount.Public.Utils.Properties.sync_public()

    {:ok, [property: property]}
  end

  test "index", %{conn: conn, property: property} do
    result =
      conn
      |> get("https://application.example.com/api/properties?code=#{property.code}")
      |> json_response(200)

    assert result["name"] == property.name
    insert(:floor_plan, property: property, name: "1234 Plan 1")
    insert(:floor_plan, property: property, name: "1234 Plan 2")

    result =
      conn
      |> get("https://application.example.com/api/properties?code=#{property.code}")
      |> json_response(200)

    assert result["name"] == property.name
    assert length(result["floor_plans"]) == 2
  end
end
