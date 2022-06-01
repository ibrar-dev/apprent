defmodule AppCountWeb.Controllers.API.UnitControllerTest do
  use AppCount.Case
  use AppCountWeb.ConnCase
  import AppCount.Factory
  import AppCount.LeasingHelper
  alias AppCount.Properties.Unit
  alias Ecto.Changeset
  @moduletag :unit_controller

  @start_date %NaiveDateTime{year: 2018, month: 1, day: 1, hour: 0, minute: 0, second: 0}
  @end_date %NaiveDateTime{year: 2019, month: 1, day: 1, hour: 0, minute: 0, second: 0}
  @charges [rent: 850]

  defmodule PropertiesParrot do
    use TestParrot

    parrot(:properties_boundary, :update_unit, {:ok, %{"unit" => %{"status" => "RENO"}}})
  end

  setup do
    property = insert(:property, setting: nil)
    insert(:setting, property_id: property.id, area_rate: 2)

    fp =
      insert(
        :floor_plan,
        property: property,
        features: [insert(:feature, property: property)]
      )

    unit = insert(:unit, property: property, floor_plan_id: fp.id, area: 550)
    unit2 = insert(:unit, property: property, floor_plan_id: fp.id, area: 650)

    %{tenancies: [tenancy1]} =
      insert_lease(%{
        start_date: @start_date,
        end_date: @end_date,
        charges: @charges,
        actual_move_in: Timex.shift(@start_date, days: 1),
        expected_move_out: Timex.shift(@end_date, days: 10),
        unit: unit,
        deposit_amount: 550
      })

    %{tenancies: [tenancy2]} =
      insert_lease(%{
        start_date: @start_date,
        end_date: @end_date,
        charges: @charges,
        actual_move_in: Timex.shift(@start_date, days: 1),
        expected_move_out: Timex.shift(@end_date, days: 10),
        unit: unit2,
        deposit_amount: 660
      })

    {
      :ok,
      [
        property: property,
        admin: admin_with_access([property.id]),
        tenancy1: tenancy1,
        tenancy2: tenancy2,
        fp: fp
      ]
    }
  end

  test "unit index works", %{
    conn: conn,
    property: property,
    tenancy1: tenancy1,
    tenancy2: tenancy2
  } do
    [unit1, unit2] =
      conn
      |> admin_request(%{property_ids: [property.id], schema: "dasmen", roles: ["Admin"]})
      |> get("http://administration.example.com/api/units?property_id=#{property.id}")
      |> json_response(200)

    assert unit1["id"] == tenancy1.unit.id
    assert unit2["id"] == tenancy2.unit.id
  end

  test "unit min index works", %{conn: conn, admin: admin, tenancy1: tenancy1, tenancy2: tenancy2} do
    [unit1, _] =
      conn
      |> admin_request(admin)
      |> get("http://administration.example.com/api/units?min=true")
      |> json_response(200)

    assert unit1["id"] == tenancy1.unit.id || unit1["id"] == tenancy2.unit.id
  end

  test "unit min index with start_date works", %{conn: conn, admin: admin, tenancy1: tenancy1} do
    [] =
      conn
      |> admin_request(admin)
      |> get("http://administration.example.com/api/units?min=true&start_date=2019-01-01")
      |> json_response(200)

    AppCount.Tenants.TenancyRepo.update(tenancy1, %{expected_move_out: "2018-12-30"})

    [unit] =
      conn
      |> admin_request(admin)
      |> get("http://administration.example.com/api/units?min=true&start_date=2019-01-01")
      |> json_response(200)

    assert unit["id"] == tenancy1.unit.id
  end

  test "unit search index works", %{
    conn: conn,
    admin: admin,
    tenancy1: tenancy1,
    tenancy2: tenancy2
  } do
    [unit1, _] =
      conn
      |> admin_request(admin)
      |> get("http://administration.example.com/api/units?search")
      |> json_response(200)

    assert unit1["id"] == tenancy1.unit.id || unit1["id"] == tenancy2.unit.id
  end

  test "available unit index works", %{conn: conn, admin: admin, property: property} do
    resp =
      conn
      |> admin_request(admin)
      |> get(
        "http://administration.example.com/api/units?property_id=#{property.id}&start=2019-01-01"
      )
      |> json_response(200)

    assert resp == []

    resp =
      conn
      |> admin_request(admin)
      |> get(
        "http://administration.example.com/api/units?property_id=#{property.id}&start=2019-01-12"
      )
      |> json_response(200)

    assert length(resp) == 2
  end

  test "rentable unit index works", %{conn: conn, admin: admin, tenancy1: tenancy1} do
    resp =
      conn
      |> admin_request(admin)
      |> get("http://administration.example.com/api/units?rentable=true")
      |> json_response(200)

    assert resp == []
    AppCount.Tenants.TenancyRepo.update(tenancy1, %{actual_move_out: AppCount.current_time()})

    resp =
      conn
      |> admin_request(admin)
      |> get("http://administration.example.com/api/units?rentable=true")
      |> json_response(200)

    assert length(resp) == 1
  end

  test "create unit works", %{conn: conn, admin: admin, property: property} do
    params = %{"number" => "AABBCC1", "property_id" => property.id}

    conn
    |> admin_request(admin)
    |> post("http://administration.example.com/api/units", %{"unit" => params})
    |> json_response(200)

    assert Repo.get_by(Unit, number: "AABBCC1", property_id: property.id)
  end

  @tag subdomain: "administration"
  test "update unit works", %{conn: conn, admin: admin} do
    params = %{"id" => 1234, "unit" => %{"new_status" => "RENO"}}

    conn =
      assign(conn, :properties_boundary, PropertiesParrot)
      |> admin_request(admin)

    conn = patch(conn, Routes.api_unit_path(conn, :update, 1234), params)

    assert json_response(conn, 200) == %{"unit" => %{"status" => "RENO"}}
    assert_receive {:update_unit, "1234", %{"new_status" => "RENO"}}
  end

  @tag subdomain: "administration"
  test "update unit fails and handles error appropriately", %{conn: conn, admin: admin} do
    PropertiesParrot.say_update_unit(
      {:error,
       Changeset.change(%AppCount.Properties.Unit{}, %{status: "1234"})
       |> Changeset.add_error(:status, "cannot be a number")}
    )

    params = %{"id" => 1234, "unit" => %{"new_status" => "4321"}}

    conn =
      assign(conn, :properties_boundary, PropertiesParrot)
      |> admin_request(admin)

    conn = patch(conn, Routes.api_unit_path(conn, :update, 1234), params)

    assert json_response(conn, 422) == %{"error" => %{"status" => ["cannot be a number"]}}
    assert_receive {:update_unit, "1234", %{"new_status" => "4321"}}
  end

  test "show unit works", %{conn: conn, tenancy1: tenancy1} do
    unit = tenancy1.unit

    resp =
      conn
      |> admin_request(%{property_ids: [tenancy1.unit.property_id], roles: ["Super Admin"]})
      |> get("http://administration.example.com/api/units/#{unit.id}")
      |> json_response(200)

    %{
      id: unit.id,
      property_id: unit.property_id,
      property_name: unit.property.name,
      number: unit.number,
      area: unit.area,
      floor_plan_id: unit.floor_plan_id,
      status: unit.status,
      area_rate: "2",
      address: unit.address
    }
    |> Enum.each(fn {k, v} ->
      assert resp["#{k}"] == v
    end)
  end

  test "delete unit works", %{conn: conn, admin: admin} do
    unit = insert(:unit)

    conn
    |> admin_request(admin)
    |> delete("http://administration.example.com/api/units/#{unit.id}")
    |> json_response(401)

    assert Repo.get(Unit, unit.id)
    super_admin = AppCount.UserHelper.new_admin(%{roles: ["Super Admin"]})

    conn
    |> admin_request(super_admin)
    |> delete("http://administration.example.com/api/units/#{unit.id}")
    |> json_response(200)

    refute Repo.get(Unit, unit.id)
  end
end
