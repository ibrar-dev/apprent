defmodule AppCount.Support.Adapters.CreditCardAuthorizeFake do
  @moduledoc """
  Provides fake data during testing
  """

  def process_payment(_amount, _source, _processor) do
    {:ok, %{transaction_id: "Authorize-transaction_id"}}
  end
end
