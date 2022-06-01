defmodule AppCountWeb.Controllers.API.RentApplicationControllerTest do
  use AppCountWeb.ConnCase
  import Mock
  alias AppCount.Ledgers.Utils.Payments
  alias AppCount.Ledgers.Payment
  @moduletag :rent_application_controller
  @url "http://application.example.com/api/rent_applications"

  @request_params %{
    "application_form" => %{
      "terms_and_conditions" => "these are the terms",
      "documents" => [],
      "emergency_contacts" => [],
      "employments" => [
        %{
          "address" => %{
            "address" => "123 Sesame St",
            "city" => "Suffern",
            "id" => "",
            "state" => "NY",
            "unit" => "",
            "zip" => "42312"
          },
          "current" => true,
          "duration" => "3 years",
          "employer" => "Dasmen Residential",
          "id" => "",
          "occupant_index" => 1,
          "phone" => "(324) 515-1234",
          "email" => "mkatz@email.com",
          "salary" => "10000",
          "supervisor" => "Michael Katz"
        }
      ],
      "histories" => [
        %{
          "address" => %{
            "address" => "3313 N. 50th Street",
            "city" => "Milwaukee",
            "id" => "",
            "state" => "WI",
            "unit" => "",
            "zip" => "53216"
          },
          "current" => true,
          "id" => "",
          "landlord_email" => "",
          "landlord_name" => "",
          "landlord_phone" => "",
          "rent" => false,
          "rental_amount" => 0,
          "residency_length" => "1 year"
        }
      ],
      "move_in" => %{
        "expected_move_in" =>
          Timex.now() |> Timex.shift(days: 5) |> Timex.format!("%Y-%m-%d", :strftime),
        "id" => "",
        "unit_id" => ""
      },
      "occupants" => [
        %{
          "cell_phone" => "",
          "dl_number" => "3214213",
          "dl_state" => "AR",
          "dob" => "1980-06-12",
          "email" => "hank@gmail.com",
          "full_name" => "Hank Mess",
          "home_phone" => "(414) 123-4234",
          "id" => "",
          "ssn" => "333-22-1111",
          "status" => "Lease Holder",
          "work_phone" => ""
        }
      ],
      "pets" => [],
      "vehicles" => []
    },
    "payment" => %{
      "amount" => 400,
      "token_description" => "COMMON.ACCEPT.INAPP.PAYMENT",
      "token_value" => "123123123123123",
      "payer_name" => "Baz Foobar",
      "payment_type" => "cc",
      "last_4" => "1234",
      "fees" => [
        %{"name" => "application_fees", "amount" => 250},
        %{"name" => "admin_fees", "amount" => 150}
      ]
    },
    "client" => "dasmen",
    "property_id" => 1
  }

  setup do
    property = insert(:property, id: 1)
    {:ok, [property: property]}
  end

  test "with a failed payment", ~M[conn, property] do
    new_conn =
      with_mock Payments,
                [:passthrough],
                process_payment: fn _, _, _ ->
                  {:error, %{reason: "Something was screwy"}}
                end do
        conn
        |> post(@url, @request_params)
      end

    assert json_response(new_conn, 422) == %{
             "error" =>
               "Payment Failure: Something was screwy. Please enter different payment information and try again, or save the application and contact the leasing office."
           }

    assert is_nil(Repo.get_by(AppCount.RentApply.RentApplication, property_id: property.id))
  end

  test "application submission works", %{conn: conn, property: property} do
    new_conn =
      with_mock Payments,
                [:passthrough],
                process_payment: fn _, _, _ ->
                  {:ok, %{transaction_id: "ssss", x: "x"}}
                end do
        conn
        |> post(@url, @request_params)
      end

    assert json_response(new_conn, 200) == %{}

    appl = Repo.get_by(AppCount.RentApply.RentApplication, property_id: property.id)
    payment = Repo.get_by(Payment, application_id: appl.id)

    assert appl.customer_ledger_id
    assert payment
    assert payment.cvv_confirmed_at
    assert payment.zip_code_confirmed_at
    assert payment.rent_application_terms_and_conditions == "these are the terms"
  end

  test "application submission works even with malformed documents", ~M[conn, property] do
    application_form =
      @request_params["application_form"]
      |> Map.merge(%{"documents" => [%{"type" => "Pay Stub", "url" => %{"uuid" => "asdfasdf"}}]})

    request_params =
      @request_params
      |> Map.put("application_form", application_form)

    new_conn =
      with_mock Payments,
                [:passthrough],
                process_payment: fn _, _, _ ->
                  {:ok, %{transaction_id: "ssss", x: "x"}}
                end do
        conn
        |> post(@url, request_params)
      end

    assert json_response(new_conn, 200) == %{}

    appl = Repo.get_by(AppCount.RentApply.RentApplication, property_id: property.id)
    assert Repo.get_by(Payment, application_id: appl.id)
    assert appl.terms_and_conditions == "these are the terms"
  end

  test "app submission creates desired receipts", %{conn: conn, property: property} do
    new_conn =
      with_mock Payments,
                [:passthrough],
                process_payment: fn _, _, _ ->
                  {:ok, %{transaction_id: "ssss", x: "x"}}
                end do
        conn
        |> post(@url, @request_params)
      end

    assert json_response(new_conn, 200) == %{}

    appl = Repo.get_by(AppCount.RentApply.RentApplication, property_id: property.id)
    payment = Repo.get_by(Payment, application_id: appl.id)
    assert payment
    assert payment.payer_ip_address == "127.0.0.1"
    assert payment.last_4 == "1234"
    assert payment.payment_type == "cc"
    assert payment.payer_name == "Baz Foobar"

    application_fees =
      AppCount.Ledgers.Utils.SpecialChargeCodes.get_charge_code(:application_fees)

    admin_fees = AppCount.Ledgers.Utils.SpecialChargeCodes.get_charge_code(:admin_fees)

    ledger =
      Repo.get(AppCount.Ledgers.CustomerLedger, payment.customer_ledger_id)
      |> Repo.preload([:charges, :payments])

    application_fee =
      Enum.find(ledger.charges, fn r -> r.charge_code_id == application_fees.id end)

    assert application_fee
    assert Decimal.eq?(application_fee.amount, 250)

    admin_fee = Enum.find(ledger.charges, fn r -> r.charge_code_id == admin_fees.id end)
    assert admin_fee
    assert Decimal.eq?(admin_fee.amount, 150)

    # Gotta make sure no other charges snuck in
    assert length(ledger.charges) == 2
    assert length(ledger.payments) == 1
  end

  test "app submission creates desired receipts with one fee", %{conn: conn, property: property} do
    params =
      Map.replace!(
        @request_params,
        "payment",
        %{
          "amount" => 250,
          "payer_name" => "Baz Foobar",
          "payment_type" => "cc",
          "last_4" => "1234",
          "fees" => [
            %{"name" => "application_fees", "amount" => 250}
          ],
          "token_description" => "COMMON.ACCEPT.INAPP.PAYMENT",
          "token_value" => "123123123123123"
        }
      )

    new_conn =
      with_mock Payments,
                [:passthrough],
                process_payment: fn _, _, _ ->
                  {:ok, %{transaction_id: "ssss", x: "x"}}
                end do
        conn
        |> post(@url, params)
      end

    appl = Repo.get_by(AppCount.RentApply.RentApplication, property_id: property.id)
    payment = Repo.get_by(Payment, application_id: appl.id)
    assert payment

    application_fees =
      AppCount.Ledgers.Utils.SpecialChargeCodes.get_charge_code(:application_fees)

    ledger =
      Repo.get(AppCount.Ledgers.CustomerLedger, payment.customer_ledger_id)
      |> Repo.preload([:charges, :payments])

    application_fee =
      Enum.find(ledger.charges, fn r -> r.charge_code_id == application_fees.id end)

    assert application_fee
    assert Decimal.eq?(application_fee.amount, 250)

    # Gotta make sure no other charges snuck in
    assert length(ledger.charges) == 1

    assert json_response(new_conn, 200) == %{}
  end

  test "app submission creates desired receipts with zeroed admin fee", %{
    conn: conn,
    property: property
  } do
    params =
      Map.replace!(
        @request_params,
        "payment",
        %{
          "amount" => 250,
          "payer_name" => "Baz Foobar",
          "payment_type" => "cc",
          "last_4" => "1234",
          "fees" => [
            %{"name" => "application_fees", "amount" => 250},
            %{"name" => "admin_fees", "amount" => 0}
          ],
          "token_description" => "COMMON.ACCEPT.INAPP.PAYMENT",
          "token_value" => "123123123123123"
        }
      )

    new_conn =
      with_mock Payments,
                [:passthrough],
                process_payment: fn _, _, _ ->
                  {:ok, %{transaction_id: "ssss", x: "x"}}
                end do
        conn
        |> post(@url, params)
      end

    appl = Repo.get_by(AppCount.RentApply.RentApplication, property_id: property.id)
    payment = Repo.get_by(Payment, application_id: appl.id)
    assert payment
    assert payment.last_4 == "1234"
    assert payment.payment_type == "cc"
    assert payment.payer_name == "Baz Foobar"

    application_fees =
      AppCount.Ledgers.Utils.SpecialChargeCodes.get_charge_code(:application_fees)

    ledger =
      Repo.get(AppCount.Ledgers.CustomerLedger, payment.customer_ledger_id)
      |> Repo.preload([:charges, :payments])

    application_fee =
      Enum.find(ledger.charges, fn r -> r.charge_code_id == application_fees.id end)

    assert application_fee
    assert Decimal.eq?(application_fee.amount, 250)

    # Gotta make sure no other charges snuck in
    assert length(ledger.charges) == 1

    assert json_response(new_conn, 200) == %{}
  end

  test "app submission creates desired receipts with no fees", %{conn: conn, property: property} do
    params =
      Map.replace!(
        @request_params,
        "payment",
        %{
          "amount" => 400,
          "token_description" => "COMMON.ACCEPT.INAPP.PAYMENT",
          "token_value" => "123123123123123",
          "payer_name" => "Baz Foobar",
          "payment_type" => "cc",
          "last_4" => "1234"
        }
      )

    new_conn =
      with_mock Payments,
                [:passthrough],
                process_payment: fn _, _, _ ->
                  {:ok, %{transaction_id: "ssss", x: "x"}}
                end do
        conn
        |> post(@url, params)
      end

    appl = Repo.get_by(AppCount.RentApply.RentApplication, property_id: property.id)
    payment = Repo.get_by(Payment, application_id: appl.id)
    assert payment

    assert payment.last_4 == "1234"
    assert payment.payment_type == "cc"
    assert payment.payer_name == "Baz Foobar"

    application_fees =
      AppCount.Ledgers.Utils.SpecialChargeCodes.get_charge_code(:application_fees)

    ledger =
      Repo.get(AppCount.Ledgers.CustomerLedger, payment.customer_ledger_id)
      |> Repo.preload([:charges, :payments])

    application_fee =
      Enum.find(ledger.charges, fn r -> r.charge_code_id == application_fees.id end)

    assert application_fee
    assert Decimal.eq?(application_fee.amount, 400)

    # Gotta make sure no other charges snuck in
    assert length(ledger.charges) == 1

    assert json_response(new_conn, 200) == %{}
  end

  test "app submission creates desired receipts with empty fees", %{
    conn: conn,
    property: property
  } do
    params =
      Map.replace!(
        @request_params,
        "payment",
        %{
          "amount" => 400,
          "token_description" => "COMMON.ACCEPT.INAPP.PAYMENT",
          "token_value" => "123123123123123",
          "payer_name" => "Baz Foobar",
          "payment_type" => "cc",
          "last_4" => "1234",
          "fees" => []
        }
      )

    new_conn =
      with_mock Payments,
                [:passthrough],
                process_payment: fn _, _, _ ->
                  {:ok, %{transaction_id: "ssss", x: "x"}}
                end do
        conn
        |> post(@url, params)
      end

    appl = Repo.get_by(AppCount.RentApply.RentApplication, property_id: property.id)
    payment = Repo.get_by(Payment, application_id: appl.id)
    assert payment
    assert payment.last_4 == "1234"
    assert payment.payment_type == "cc"
    assert payment.payer_name == "Baz Foobar"

    application_fees =
      AppCount.Ledgers.Utils.SpecialChargeCodes.get_charge_code(:application_fees)

    ledger =
      Repo.get(AppCount.Ledgers.CustomerLedger, payment.customer_ledger_id)
      |> Repo.preload([:charges, :payments])

    application_fee =
      Enum.find(ledger.charges, fn r -> r.charge_code_id == application_fees.id end)

    assert application_fee
    assert Decimal.eq?(application_fee.amount, 400)

    # Gotta make sure no other charges snuck in
    assert length(ledger.charges) == 1
    assert length(ledger.payments) == 1

    assert json_response(new_conn, 200) == %{}
  end
end
