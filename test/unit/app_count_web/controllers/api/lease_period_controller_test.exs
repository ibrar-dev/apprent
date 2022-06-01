defmodule AppCountWeb.Controllers.API.LeasePeriodControllerTest do
  use AppCountWeb.ConnCase
  @moduletag :lease_period_controller

  setup do
    property = insert(:property)
    admin = admin_with_access([property.id])
    period = insert(:renewal_period, property: property)

    insert(:renewal_package,
      min: 7,
      max: 8,
      amount: 10,
      dollar: false,
      base: "Current Rent",
      renewal_period: period
    )

    {:ok, property: property, admin: admin}
  end

  test "index", %{conn: conn, admin: admin, property: property} do
    conn
    |> admin_request(admin)
    |> get("http://administration.example.com/api/lease_periods?property_id=#{property.id}")
    |> json_response(200)
    |> length
    |> Kernel.==(1)
    |> assert
  end
end
