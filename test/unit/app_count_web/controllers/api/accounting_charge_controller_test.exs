defmodule AppCountWeb.Controllers.API.AccountingChargeControllerTest do
  use AppCountWeb.ConnCase
  alias AppCount.Repo
  alias AppCount.Ledgers.Charge
  @moduletag :accounting_charge_controller

  setup do
    admin = AppCount.UserHelper.new_admin()

    {:ok, admin: admin, charge_code: insert(:charge_code), lease: insert(:lease)}
  end

  test "create_charge", %{conn: conn, admin: admin, charge_code: charge_code, lease: lease} do
    creation_parameters = %{
      "charges" => [
        %{
          "charge_code_id" => charge_code.id,
          "amount" => "233",
          "bill_date" => "2019-04-04",
          "description" => "Nice and random",
          "lease_id" => lease.id
        }
      ]
    }

    resp =
      conn
      |> admin_request(admin)
      |> post("http://administration.example.com/api/accounting_charges", creation_parameters)

    assert json_response(resp, 200) == %{}

    assert Repo.get_by(
             Charge,
             lease_id: lease.id,
             charge_code_id: charge_code.id,
             amount: 233,
             bill_date: %Date{
               year: 2019,
               month: 4,
               day: 4
             }
           )
  end

  test "creates batch charges", %{
    conn: conn,
    admin: admin,
    charge_code: charge_code,
    lease: lease
  } do
    creation_parameters = %{
      "batch_charges" => [
        %{
          "charge_code_id" => charge_code.id,
          "amount" => "15",
          "description" => "Broken Window",
          "status" => "manual"
        }
      ],
      "date" => "2019-04-04",
      "lease_id" => lease.id
    }

    resp =
      conn
      |> admin_request(admin)
      |> post("http://administration.example.com/api/accounting_charges", creation_parameters)

    assert json_response(resp, 200) == %{}

    assert Repo.get_by(
             Charge,
             lease_id: lease.id,
             charge_code_id: charge_code.id,
             amount: 15,
             bill_date: %Date{
               year: 2019,
               month: 4,
               day: 4
             }
           )
  end

  test "update_charge", %{conn: conn, admin: admin, charge_code: charge_code, lease: lease} do
    charge = insert(:bill, charge_code: charge_code, lease: lease)

    params = %{
      "charge" => %{
        "amount" => "1234",
        "description" => "Updated Description"
      }
    }

    resp =
      conn
      |> admin_request(admin)
      |> patch("http://administration.example.com/api/accounting_charges/#{charge.id}", params)

    assert json_response(resp, 200) == %{}
    updated = Repo.get(Charge, charge.id)
    assert Decimal.equal?(updated.amount, Decimal.new(1234))
    assert updated.description == "Updated Description"
  end

  test "delete_charge", %{conn: conn, admin: admin} do
    charge = insert(:bill)
    date = Timex.format!(AppCount.current_time(), "{YYYY}-{M}-{D}")

    post_month =
      Timex.beginning_of_month(AppCount.current_time()) |> Timex.format!("{YYYY}-{M}-{D}")

    resp =
      conn
      |> admin_request(admin)
      |> delete(
        "http://administration.example.com/api/accounting_charges/#{charge.id}?date=#{date}&post_month=#{
          post_month
        }"
      )

    assert json_response(resp, 200) == %{}
    assert Repo.get(Charge, charge.id).reversal_id

    conn
    |> admin_request(admin)
    |> delete(
      "http://administration.example.com/api/accounting_charges/#{charge.id}?destroy=true"
    )
    |> json_response(403)

    assert Repo.get(Charge, charge.id)
    new_admin = AppCount.UserHelper.new_admin(%{roles: ["Super Admin"]})

    conn
    |> admin_request(new_admin)
    |> delete(
      "http://administration.example.com/api/accounting_charges/#{charge.id}?destroy=true"
    )
    |> json_response(200)

    refute Repo.get(Charge, charge.id)
  end

  test "upload CSV", %{conn: conn, admin: admin} do
    upload = %Plug.Upload{
      content_type: "text/csv",
      filename: "utilities.csv",
      path: Path.expand("../../../resources/utilities.csv", __DIR__)
    }

    params = %{"property_id" => insert(:property).id, "data" => upload}

    conn
    |> admin_request(admin)
    |> post("http://administration.example.com/api/accounting_charges", params)
    |> json_response(200)
    |> assert
  end

  test "creates a batch of charges", %{conn: conn, admin: admin, charge_code: charge_code} do
    lease1 = insert(:lease)
    lease2 = insert(:lease)
    lease3 = insert(:lease)

    creation_parameters = %{
      "batch" => %{
        "charge_code_id" => charge_code.id,
        "note" => "Some Note",
        "postDate" => "2019-04-22T09:00:00.000Z",
        "postMonth" => "2019-04-01",
        "residents" => [
          %{
            "amount" => "150",
            "lease_id" => lease1.id
          },
          %{
            "amount" => "100",
            "lease_id" => lease2.id
          },
          %{
            "amount" => "50",
            "lease_id" => lease3.id
          }
        ]
      }
    }

    resp =
      conn
      |> admin_request(admin)
      |> post("http://administration.example.com/api/accounting_charges", creation_parameters)

    assert json_response(resp, 200) == %{}
    assert Repo.get_by(Charge, lease_id: lease1.id, charge_code_id: charge_code.id, amount: 150)
    assert Repo.get_by(Charge, lease_id: lease2.id, charge_code_id: charge_code.id, amount: 100)
    assert Repo.get_by(Charge, lease_id: lease3.id, charge_code_id: charge_code.id, amount: 50)
  end
end
