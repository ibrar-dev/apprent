defmodule AppCountWeb.Users.PaymentControllerTest do
  use AppCountWeb.ConnCase

  defmodule PaymentBoundaryParrot do
    use TestParrot
    alias AppCount.Core.PaymentBoundaryBehaviour
    @behaviour PaymentBoundaryBehaviour

    parrot(:payment, :create_payment, {:ok, rent_saga()})

    def rent_saga do
      %AppCount.Core.RentSaga{
        id: 8_383_838,
        account: %AppCount.Accounts.Account{id: 123},
        payment_source_id: 543,
        amount_in_cents: 80_000,
        payment_confirmed_at: AppCount.Core.Clock.now(),
        account_id: 123,
        cvv_confirmed_at: AppCount.Core.Clock.now(),
        zip_code_confirmed_at: AppCount.Core.Clock.now(),
        property_id: 67
      }
    end
  end

  setup(~M[conn]) do
    account =
      insert(:user_account)
      |> AppCount.UserHelper.new_account()

    conn =
      conn
      |> user_request(account)
      |> put_req_header("content-type", "application/json")

    ~M[conn]
  end

  describe "create_payment" do
    setup(~M[conn]) do
      conn = assign(conn, :payment_boundary, PaymentBoundaryParrot)
      amount_in_cents = 80_000
      agreement_text = "I agree"
      payment_source_id = "444"
      account_id = "123"

      params = %{
        "payment" => %{
          "payment_source_id" => payment_source_id,
          "amount_in_cents" => amount_in_cents,
          "agreement_text" => agreement_text,
          "account_id" => account_id
        }
      }

      ~M[conn, params, amount_in_cents, agreement_text, payment_source_id]
    end

    @tag subdomain: "residents"
    test "create :ok",
         ~M[conn, params, amount_in_cents, payment_source_id, agreement_text] do
      # When
      conn = post(conn, Routes.user_resident_payment_path(conn, :create), params)

      result =
        json_response(conn, 201)
        |> Map.drop(["started_at"])

      assert result == %{
               "amount_in_cents" => amount_in_cents,
               "surcharge_in_cents" => 0,
               "payment_confirmed_at" => AppCount.Core.Clock.now() |> DateTime.to_iso8601(),
               "payment_source_id" => 543,
               "failed_at" => nil,
               "zip_code_confirmed_at" => AppCount.Core.Clock.now() |> DateTime.to_iso8601(),
               "cvv_confirmed_at" => AppCount.Core.Clock.now() |> DateTime.to_iso8601(),
               "property_id" => 67
             }

      assert_receive {:create_payment, _account_id,
                      {^amount_in_cents, ^payment_source_id, ^agreement_text}}
    end

    test "create :error with message", ~M[conn, params] do
      PaymentBoundaryParrot.say_create_payment({:error, "some message"})

      # When
      conn = post(conn, Routes.user_resident_payment_path(conn, :create), params)

      # Then
      assert json_response(conn, 400) == %{"error" => "some message"}
    end

    test "create :error with changeset", ~M[conn, params] do
      PaymentBoundaryParrot.say_create_payment(
        {:error, %AppCount.Core.RentSaga{message: "Things are bad"}}
      )

      # when
      conn = post(conn, Routes.user_resident_payment_path(conn, :create), params)

      # then
      assert json_response(conn, 400) == %{"error" => "Things are bad"}
    end

    test "create :error with weird changeset", ~M[conn, params] do
      PaymentBoundaryParrot.say_create_payment({:error, %AppCount.Core.RentSaga{message: nil}})

      # when
      conn = post(conn, Routes.user_resident_payment_path(conn, :create), params)

      # then
      assert json_response(conn, 400) == %{"error" => "Unknown Error"}
    end

    test "create :error unknown", ~M[conn, params] do
      PaymentBoundaryParrot.say_create_payment(:error)

      # When
      conn = post(conn, Routes.user_resident_payment_path(conn, :create), params)

      # Then
      assert json_response(conn, 400) == %{"error" => "Unknown Error"}
    end
  end
end
