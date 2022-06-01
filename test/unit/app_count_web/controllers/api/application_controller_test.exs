defmodule AppCountWeb.API.ApplicationControllerTest do
  use AppCountWeb.ConnCase
  alias AppCountWeb.API.ApplicationController
  alias AppCount.RentApply.RentApplication
  alias AppCount.RentApply.Memo
  alias AppCount.Repo
  alias AppCount.Core.Clock
  @moduletag :application_controller

  @request_params %{
    "approve" => %{
      "persons" => [
        %{
          "email" => "arthur@camelot.com",
          "phone" => "(123) 412-4144",
          "first_name" => "Hank",
          "last_name" => "Mess",
          "status" => "Lease Holder"
        }
      ],
      "end_date" => "2019-11-05",
      "rent" => "900",
      "start_date" => "2018-11-05",
      "unit_id" => 1
    },
    "id" => 1
  }

  @decline_params %{
    "declined_reason" => "He So Ugly",
    "id" => 1
  }

  @memo_params %{
    "application_id" => 1,
    "note" => "this is a note",
    "memos" => true
  }

  setup do
    property = insert(:property)

    charge_codes = [insert(:charge_code), insert(:charge_code)]

    admin = admin_with_access([property.id])
    rent_application = insert(:rent_application, %{id: 1, property: property})
    insert(:unit, %{id: 1, property: property})

    {:ok,
     charge_codes: charge_codes,
     admin: admin,
     rent_application: rent_application,
     property: property}
  end

  def valid_dates() do
    start_date =
      Clock.today()
      |> Timex.shift(days: -30)
      |> Timex.format!("%Y-%m-%d", :strftime)

    end_date =
      Clock.today()
      |> Timex.format!("%Y-%m-%d", :strftime)

    [start_date, end_date]
  end

  def invalid_dates() do
    start_date =
      Clock.today()
      |> Timex.shift(days: 30)
      |> Timex.format!("%Y-%m-%d", :strftime)

    end_date =
      Clock.today()
      |> Timex.shift(days: 31)
      |> Timex.format!("%Y-%m-%d", :strftime)

    [start_date, end_date]
  end

  test "get payment url works", %{conn: conn, admin: admin} do
    result =
      conn
      |> admin_request(admin)
      |> get("http://administration.example.com/api/applications/199?payment_url=true")
      |> json_response(200)

    assert result["url"] =~ ~r"http://application\..*/payment/.*"
  end

  test "application approval works", %{conn: conn, charge_codes: [cc1, cc2]} do
    charge_data = [
      %{"charge_code_id" => cc1.id, "amount" => "20"},
      %{"charge_code_id" => cc2.id, "amount" => "57"}
    ]

    params = update_in(@request_params["approve"], &Map.put(&1, "charges", charge_data))
    new_conn = ApplicationController.update(conn, params)
    assert json_response(new_conn, 200) == %{}
    new_appl = Repo.get(RentApplication, 1)
    assert new_appl.status == "preapproved"
  end

  test "decline application works", %{conn: conn, admin: admin} do
    new_conn =
      conn
      |> admin_request(admin)
      |> patch(
        "http://administration.example.com/api/applications/#{@decline_params["id"]}",
        @decline_params
      )

    assert json_response(new_conn, 200) == %{}
    new_app = Repo.get(RentApplication, 1)
    assert new_app.status == "declined"
    assert new_app.declined_by == admin.name
    assert new_app.declined_reason == "He So Ugly"
  end

  test "create memo works", %{conn: conn, admin: admin} do
    refute Repo.get_by(Memo, note: "this is a note", application_id: 1, admin_id: admin.id)

    new_conn =
      conn
      |> admin_request(admin)
      |> post(
        "http://administration.example.com/api/applications",
        @memo_params
      )

    assert json_response(new_conn, 200) == %{}

    assert Repo.get_by(Memo, note: "this is a note", application_id: 1, admin_id: admin.id)
  end

  test "get applications works with no dates", %{conn: conn, admin: admin, property: property} do
    new_conn =
      conn
      |> admin_request(admin)
      |> get("http://administration.example.com/api/applications?property_id=#{property.id}")

    %{"applications" => apps} = json_response(new_conn, 200)

    assert json_response(new_conn, 200)
    assert length(apps) == 1
  end

  test "get applications works with dates", %{conn: conn, admin: admin, property: property} do
    [start_date, end_date] = valid_dates()

    new_conn =
      conn
      |> admin_request(admin)
      |> get(
        "http://administration.example.com/api/applications?property_id=#{property.id}&start_date=#{
          start_date
        }&end_date=#{end_date}"
      )

    %{"applications" => apps} = json_response(new_conn, 200)

    assert json_response(new_conn, 200)
    assert length(apps) == 1
  end

  test "get applications works with bad dates", %{conn: conn, admin: admin, property: property} do
    [start_date, end_date] = invalid_dates()

    new_conn =
      conn
      |> admin_request(admin)
      |> get(
        "http://administration.example.com/api/applications?property_id=#{property.id}&start_date=#{
          start_date
        }&end_date=#{end_date}"
      )

    %{"applications" => apps} = json_response(new_conn, 200)

    assert json_response(new_conn, 200)
    assert apps == []
  end
end
