defmodule AppCountWeb.Controllers.API.PropertyReportControllerTest do
  use AppCount.Case
  use AppCountWeb.ConnCase
  import AppCount.{Factory, LeaseHelper}
  @moduletag :property_report_controller

  setup do
    property = insert(:property)

    insert_lease(%{
      start_date: AppCount.current_date(),
      end_date: Timex.shift(AppCount.current_date(), months: 12),
      charges: [
        Rent: 1000
      ],
      unit: insert(:unit, property: property)
    })

    {
      :ok,
      admin: admin_with_access([property.id]), property: property
    }
  end

  @tag :slow
  test "rent_roll", %{conn: conn, admin: admin, property: property} do
    date =
      AppCount.current_date()
      |> Timex.shift(days: 2)

    resp =
      conn
      |> admin_request(admin)
      |> get(
        "https://administration.example.com/api/property_report?property_id=#{property.id}&rent_roll=true&date=#{
          date
        }"
      )
      |> json_response(200)

    assert resp["rent_roll_potent"]
    assert resp["rent_roll_real"]
  end

  test "delinquency", %{conn: conn, admin: admin, property: property} do
    date =
      AppCount.current_date()
      |> Timex.shift(days: 2)

    resp =
      conn
      |> admin_request(admin)
      |> get(
        "https://administration.example.com/api/property_report?property_id=#{property.id}&delinquency=true&date=#{
          date
        }"
      )
      |> json_response(200)

    assert resp
  end

  test "daily_deposit", %{conn: conn, admin: admin, property: property} do
    date =
      AppCount.current_date()
      |> Timex.shift(days: 2)

    resp =
      conn
      |> admin_request(admin)
      |> get(
        "https://administration.example.com/api/property_report?property_id=#{property.id}&daily_deposit=true&date=#{
          date
        }"
      )
      |> json_response(200)

    assert resp["wtd_new_leases"]
  end

  test "move_outs", %{conn: conn, admin: admin, property: property} do
    start_date =
      AppCount.current_date()
      |> Timex.shift(days: -200)

    end_date =
      AppCount.current_date()
      |> Timex.shift(days: 2)

    resp =
      conn
      |> admin_request(admin)
      |> get(
        "https://administration.example.com/api/property_report?property_id=#{property.id}&move_outs=true&start_date=#{
          end_date
        }&end_date=#{start_date}"
      )
      |> json_response(200)

    assert resp
  end

  test "open_make_ready_report", %{conn: conn, admin: admin, property: property} do
    date =
      AppCount.current_date()
      |> Timex.shift(days: 2)

    resp =
      conn
      |> admin_request(admin)
      |> get(
        "https://administration.example.com/api/property_report?property_id=#{property.id}&open_make_ready_report=true&date=#{
          date
        }"
      )
      |> json_response(200)

    assert length(resp) == 1
  end

  test "boxscore availability", %{conn: conn, admin: admin, property: property} do
    start_date =
      AppCount.current_date()
      |> Timex.shift(days: -30)

    end_date =
      AppCount.current_date()
      |> Timex.shift(days: -1)

    dates = "#{start_date},#{end_date}"

    resp =
      conn
      |> admin_request(admin)
      |> get(
        "https://administration.example.com/api/property_report?property_id=#{property.id}&box_score=true&dates=#{
          dates
        }&type=availability"
      )
      |> json_response(200)

    assert resp["floor_plans"]
    assert resp["property_calculations"]
  end

  test "boxscore residentActivity", %{conn: conn, admin: admin, property: property} do
    start_date =
      AppCount.current_date()
      |> Timex.shift(days: -30)

    end_date =
      AppCount.current_date()
      |> Timex.shift(days: -1)

    dates = "#{start_date},#{end_date}"

    resp =
      conn
      |> admin_request(admin)
      |> get(
        "https://administration.example.com/api/property_report?property_id=#{property.id}&box_score=true&dates=#{
          dates
        }&type=residentActivity"
      )
      |> json_response(200)

    assert resp
  end

  test "boxscore firstContact", %{conn: conn, admin: admin, property: property} do
    start_date =
      AppCount.current_date()
      |> Timex.shift(days: -30)

    end_date =
      AppCount.current_date()
      |> Timex.shift(days: -1)

    dates = "#{start_date},#{end_date}"

    resp =
      conn
      |> admin_request(admin)
      |> get(
        "https://administration.example.com/api/property_report?property_id=#{property.id}&box_score=true&dates=#{
          dates
        }&type=firstContact"
      )
      |> json_response(200)

    assert resp
  end

  test "mtm", %{conn: conn, admin: admin, property: property} do
    resp =
      conn
      |> admin_request(admin)
      |> get(
        "https://administration.example.com/api/property_report?property_id=#{property.id}&mtm=true"
      )
      |> json_response(200)

    assert resp
  end

  test "collection", %{conn: conn, admin: admin, property: property} do
    resp =
      conn
      |> admin_request(admin)
      |> get(
        "https://administration.example.com/api/property_report?property_id=#{property.id}&collection=true"
      )
      |> json_response(200)

    assert resp
  end

  test "specific_property_report", %{conn: conn, admin: admin, property: property} do
    resp =
      conn
      |> admin_request(admin)
      |> get(
        "https://administration.example.com/api/property_report?property_ids=#{property.id},1"
      )
      |> json_response(200)

    assert resp["maintenance_info"]
    assert resp["property_info"]
    assert resp["resident_info"]
  end

  test "property_report", %{conn: conn, admin: admin} do
    resp =
      conn
      |> admin_request(admin)
      |> get("https://administration.example.com/api/property_report")
      |> json_response(200)

    assert resp["maintenance_info"]
    assert resp["property_info"]
    assert resp["resident_info"]
  end
end
