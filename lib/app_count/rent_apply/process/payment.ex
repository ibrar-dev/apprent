defmodule AppCount.RentApply.Process.Payment do
  alias AppCount.Ledgers.Utils.Payments

  def process(property_id, amount, token_description, token_value) do
    source = %{token_description: token_description, token_value: token_value, type: "cc"}

    Payments.process_payment(property_id, amount, source)
    |> case do
      {:error, %{reason: reason}} -> {:error, %{payment_declined: reason}}
      {:ok, response} -> {:ok, response}
    end
  end
end
