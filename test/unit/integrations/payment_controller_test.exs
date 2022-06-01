defmodule AppCountWeb.Integrations.PaymentControllerTest do
  use AppCountWeb.ConnCase
  use AppCountWeb.IntegrationHelper
  alias AppCount.Support.AccountBuilder
  alias AppCount.Core.DomainEvent
  alias AppCount.Core.ClientSchema
  alias AppCount.Accounts.RentSagaRepo

  setup(~M[conn]) do
    setup_adapters()

    AppCount.Core.PaymentTopic.subscribe()

    [builder, property] =
      PropBuilder.new(:create)
      |> PropBuilder.add_property()
      |> PropBuilder.add_property_setting()
      |> PropBuilder.add_processor(type: "cc")
      |> PropBuilder.get([:property])

    tenant =
      builder
      |> PropBuilder.add_unit()
      |> PropBuilder.add_tenant()
      |> PropBuilder.add_lease()
      |> PropBuilder.get_requirement(:tenant)

    [_builder, account, payment_source] =
      AccountBuilder.new(:create)
      |> AccountBuilder.put_requirement(:tenant, tenant)
      |> AccountBuilder.put_requirement(:property, property)
      |> AccountBuilder.add_account()
      |> AccountBuilder.add_payment_source()
      |> AccountBuilder.get([:account, :payment_source])

    account =
      account
      |> AppCount.UserHelper.new_account()

    conn =
      conn
      |> user_mobile_request(account)

    agreement_text = "I do from the controller"
    amount_in_cents = 100_000
    surcharge_in_cents = 3_000
    payment_source_id = payment_source.id

    params = %{
      "payment" => %{
        "payment_source_id" => payment_source_id,
        "amount_in_cents" => amount_in_cents,
        "agreement_text" => agreement_text,
        "account_id" => account.id
      }
    }

    ~M[conn, builder, params, surcharge_in_cents, agreement_text, payment_source_id, amount_in_cents, account]
  end

  describe "create_payment" do
    @tag :slow
    test "create :ok",
         ~M[conn,  params, amount_in_cents, surcharge_in_cents, payment_source_id, agreement_text, account] do
      # When
      conn = post(conn, Routes.api_v2_payment_path(conn, :create), params)

      # Then
      result =
        json_response(conn, 201)
        |> Map.drop([
          "started_at",
          "payment_confirmed_at",
          "cvv_confirmed_at",
          "zip_code_confirmed_at"
        ])

      assert result == %{
               "amount_in_cents" => amount_in_cents,
               "surcharge_in_cents" => surcharge_in_cents,
               "payment_source_id" => payment_source_id,
               "failed_at" => nil,
               "property_id" => account.property_id
             }

      assert_receive %DomainEvent{
        name: "payment_confirmed",
        topic: "payments",
        source: AppCount.Core.PaymentBoundary,
        content: %ClientSchema{
          name: "dasmen",
          attrs: %{
            rent_saga_id: rent_saga_id
          }
        }
      }

      completed_rent_saga = RentSagaRepo.get(rent_saga_id)
      assert completed_rent_saga
      assert completed_rent_saga.started_at
      assert completed_rent_saga.payment_confirmed_at
      assert completed_rent_saga.message == "Succeeded"
      assert completed_rent_saga.ip_address == "127.0.0.1"
      assert completed_rent_saga.agreement_text == agreement_text
      assert completed_rent_saga.originating_device == "mobile"

      assert completed_rent_saga.amount_in_cents == amount_in_cents
      assert completed_rent_saga.surcharge_in_cents == surcharge_in_cents

      assert completed_rent_saga.total_amount_in_cents ==
               amount_in_cents + surcharge_in_cents

      refute completed_rent_saga.failed_at

      assert completed_rent_saga.response_from_adapter ==
               ~s[%{transaction_id: "Authorize-transaction_id"}]
    end
  end
end
