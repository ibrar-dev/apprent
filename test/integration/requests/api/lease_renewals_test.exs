defmodule AppCountWeb.Requests.API.LeaseRenewalsTest do
  use AppCountWeb.ConnCase
  @moduletag :lease_renewal_controller

  setup do
    property = insert(:property)

    {:ok,
     period: insert(:renewal_period, property: property),
     property: property,
     admin: %{roles: ["Regional", "Admin"], property_ids: [property.id]}}
  end

  test "GET /api/lease_renewals valid_dates", %{
    conn: conn,
    admin: admin,
    property: property,
    period: period
  } do
    start_date = Timex.shift(period.start_date, days: -1)
    end_date = Timex.shift(period.end_date, days: 1)

    response =
      conn
      |> admin_request(admin)
      |> get(
        "https://administration.example.com/api/lease_renewals?valid_dates=t&property_id=#{
          property.id
        }&start_date=#{start_date}&end_date=#{end_date}"
      )
      |> json_response(200)

    assert response == %{"leases" => 0, "valid" => false}
  end
end
