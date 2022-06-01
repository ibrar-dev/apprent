defmodule AppCountWeb.Controllers.API.EventControllerTest do
  use AppCount.Case
  use AppCountWeb.ConnCase
  import AppCount.{Factory, LeaseHelper}
  @moduletag :event_controller

  setup do
    property = insert(:property)
    {:ok, [property: property]}
  end

  test "index", %{property: property, conn: conn} do
    result =
      conn
      |> admin_request(%{property_ids: [property.id]})
      |> get("https://administration.example.com/api/events")
      |> json_response(200)

    assert Enum.empty?(result["move_out"])
    assert Enum.empty?(result["move_in"])
    assert Enum.empty?(result["showing"])
    assert Enum.empty?(result["resident_event"])

    now = AppCount.current_date()
    start = Timex.shift(now, years: -1)

    insert_lease(%{
      start_date: start,
      end_date: now,
      move_out_date: now,
      unit: insert(:unit, property: property)
    })

    insert_lease(%{
      start_date: now,
      end_date: Timex.shift(now, years: 1),
      expected_move_in: now,
      unit: insert(:unit, property: property)
    })

    result =
      conn
      |> admin_request(%{property_ids: [property.id]})
      |> get("https://administration.example.com/api/events")
      |> json_response(200)

    assert length(result["move_out"]) == 1
    assert length(result["move_in"]) == 1
  end
end
