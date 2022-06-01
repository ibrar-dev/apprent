defmodule AppCount.Finance.Money do
  def amount_as_string(amount_in_cents) do
    :io_lib.format("~.2f", [amount_in_cents / 100])
    |> to_string()
  end
end
