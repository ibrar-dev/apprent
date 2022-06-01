defmodule AppCountWeb.Controllers.API.LeaseChargeControllerTest do
  use AppCountWeb.ConnCase
  alias AppCount.Accounting
  alias AppCount.Leasing.Charge
  @moduletag :ease_charge_controller

  setup do
    new_admin = AppCount.UserHelper.new_admin()

    {:ok,
     admin: new_admin,
     charge_code: insert(:charge_code),
     lease: insert(:leasing_lease, start_date: "2019-04-04")}
  end

  test "create", %{conn: conn, admin: admin, charge_code: charge_code, lease: lease} do
    rent_cc_id = Accounting.SpecialAccounts.get_charge_code(:rent).id

    creation_parameters = %{
      "lease_id" => lease.id,
      "charges" => [
        %{
          "charge_code_id" => rent_cc_id,
          "amount" => "1000"
        },
        %{
          "charge_code_id" => charge_code.id,
          "amount" => "200",
          "from_date" => "2019-04-04"
        }
      ]
    }

    resp =
      conn
      |> admin_request(admin)
      |> post("http://administration.example.com/api/lease_charges", creation_parameters)

    assert json_response(resp, 200) == %{}

    charge =
      Repo.get_by(
        Charge,
        lease_id: lease.id,
        charge_code_id: charge_code.id,
        amount: 200
      )

    assert charge

    rent_charge =
      Repo.get_by(
        Charge,
        lease_id: lease.id,
        charge_code_id: rent_cc_id,
        amount: 1000
      )

    assert rent_charge

    update_parameters = %{
      "lease_id" => lease.id,
      "charges" => [
        %{
          "id" => rent_charge.id,
          "charge_code_id" => Accounting.SpecialAccounts.get_charge_code(:rent).id,
          "amount" => "1000",
          "from_date" => "2019-04-04",
          "to_date" => "2019-09-30"
        },
        %{
          "charge_code_id" => rent_cc_id,
          "amount" => "1200",
          "from_date" => "2019-10-01"
        }
      ]
    }

    resp =
      conn
      |> admin_request(admin)
      |> post("http://administration.example.com/api/lease_charges", update_parameters)

    assert json_response(resp, 200) == %{}
    refute Repo.get(Charge, charge.id, prefix: "dasmen")
    reloaded = Repo.get(Charge, rent_charge.id, prefix: "dasmen")
    assert reloaded.from_date == %Date{year: 2019, month: 4, day: 4}
    assert reloaded.to_date == %Date{year: 2019, month: 9, day: 30}

    assert Repo.get_by(
             Charge,
             lease_id: lease.id,
             charge_code_id: rent_cc_id,
             amount: 1200,
             from_date: %Date{
               year: 2019,
               month: 10,
               day: 1
             }
           )
  end

  # test "create validations", %{conn: conn, admin: admin, charge_code: charge_code, lease: lease} do
  #   creation_parameters = %{
  #     "lease_id" => lease.id,
  #     "charges" => [
  #       %{
  #         "charge_code_id" => charge_code.id,
  #         "amount" => "200",
  #         "from_date" => "2019-04-04"
  #       }
  #     ]
  #   }

  #   resp =
  #     conn
  #     |> admin_request(admin)
  #     |> post("http://administration.example.com/api/lease_charges", creation_parameters)

  #   assert json_response(resp, 422) == %{"error" => "No rent charge"}

  #   rent_account_id = Accounting.SpecialAccounts.get_charge_code(:rent).id

  #   creation_parameters = %{
  #     "lease_id" => lease.id,
  #     "charges" => [
  #       %{
  #         "charge_code_id" => rent_account_id,
  #         "amount" => "200",
  #         "from_date" => "2019-04-04",
  #         "to_date" => "2020-04-04"
  #       }
  #     ]
  #   }

  #   resp =
  #     conn
  #     |> admin_request(admin)
  #     |> post("http://administration.example.com/api/lease_charges", creation_parameters)

  #   assert json_response(resp, 422) == %{
  #            "error" => "Must have at least one open ended rent charge"
  #          }
  # end
end
