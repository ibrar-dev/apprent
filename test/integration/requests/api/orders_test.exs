defmodule AppCountWeb.Requests.API.OrdersTest do
  use AppCountWeb.ConnCase
  use AppCount.DataCase

  setup do
    property = insert(:property)
    order = insert(:order, property: property)
    tech = insert(:tech)

    {
      :ok,
      order: order,
      property: property,
      tech: tech,
      admin: %{
        id: 1,
        property_ids: [property.id],
        roles: ["Tech"]
      }
    }
  end

  test "GET /api/orders", %{conn: conn, order: order, property: property, admin: admin} do
    start = Timex.format!(order.inserted_at, "{YYYY}-{0M}-{0D}")

    end_date =
      Timex.shift(order.inserted_at, days: 1)
      |> Timex.format!("{YYYY}-{0M}-{0D}")

    dates = "#{start},#{end_date}"

    response =
      conn
      |> admin_request(admin)
      |> get(
        "https://administration.example.com/api/orders?new=t&properties=#{property.id}&dates=#{
          dates
        }"
      )
      |> json_response(200)

    assert response["assigned"] == []
    assert response["cancelled"] == []
    assert response["completed"] == []
    assert length(response["unassigned"]) == 1
  end

  test "GET /api/orders type", %{conn: conn, admin: admin, order: order} do
    response =
      conn
      |> admin_request(admin)
      |> get(
        "https://administration.example.com/api/orders?type=#{order.status}&property_id=#{
          order.property.id
        }"
      )
      |> json_response(200)

    assert response == [
             %{
               "category" => "#{order.category.parent.name} #{order.category.name}",
               "id" => order.id,
               "status" => "unassigned",
               "unit" => "#{order.unit.number}",
               "unit_id" => order.unit.id
             }
           ]
  end
end
