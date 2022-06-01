defmodule AppCount.Integrations.PaymentBoundaryTest do
  @moduledoc """
  This is an INTEGRATION testfor :error.
  The point is to make sure that the stack of calls is connected correctly.
  It does not attempt to check the correctnes of various logic branches.
  Tests for that are in the unit tests.
  """
  use AppCount.DataCase, async: false
  use AppCountWeb.IntegrationHelper

  alias AppCount.Core.PaymentBoundary
  alias AppCount.Support.AccountBuilder

  # use AppCountWeb.IntegrationHelper

  setup do
    setup_adapters()

    [builder, property, _credit_card_processor] =
      PropBuilder.new(:create)
      |> PropBuilder.add_property()
      |> PropBuilder.add_processor(type: "ba")
      |> PropBuilder.get([:property, :processor])

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

    ip_address = "127.0.0.0"
    ~M[builder, account, payment_source, property, ip_address]
  end

  test "error: fails on missing amount_in_cents", ~M[account, payment_source] do
    # When
    assert {:error, actual_message} =
             PaymentBoundary.create_payment(
               {"dasmen", account.id, "127.0.0.0", "web"},
               {nil, payment_source.id, "agreement_text"}
             )

    assert actual_message == "You must provide a payment amount"
  end

  @tag :slow
  test "Write error message to Logger, processor missing",
       ~M[account, property, payment_source] do
    # When
    {:error, actual_message} =
      PaymentBoundary.create_payment(
        {"dasmen", account.id, "127.0.0.0", "web"},
        {2, payment_source.id, "agreement_text"}
      )

    assert actual_message =~
             "select_payment_source failed for Property: #{property.id} RentSaga:"
  end
end
