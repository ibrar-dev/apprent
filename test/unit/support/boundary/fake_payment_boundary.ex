defmodule AppCount.Core.FakePaymentBoundary do
  @moduledoc """
  PaymentBoundaryFake
  """
  alias AppCount.Core.RentSaga
  alias AppCount.Core.PaymentBoundaryBehaviour
  alias AppCount.Accounts.Account
  @behaviour PaymentBoundaryBehaviour

  @impl PaymentBoundaryBehaviour
  def create_payment(account_ip_tuple, param_tuple)

  def create_payment({_account_id, _ip_address}, {-100_000, _payment_source_id, _agreement_text}) do
    {:error, "unknown error"}
  end

  def create_payment(
        {account_id, ip_address},
        {amount_in_cents, _payment_source_id, _agreement_text}
      ) do
    rent_saga = %RentSaga{
      id: account_id,
      account: %Account{id: account_id},
      ip_address: ip_address,
      amount_in_cents: amount_in_cents,
      message: "created by #{__MODULE__}"
    }

    {:ok, rent_saga}
  end
end
