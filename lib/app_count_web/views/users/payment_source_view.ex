defmodule AppCountWeb.Users.PaymentSourceView do
  use AppCountWeb.Users, :view

  # Format a Credit Card as "Visa: XXXX 1234"
  def payment_source_display_name(%{type: "cc"} = source) do
    "#{String.capitalize(source.brand)}: XXXX #{source.last_4}"
  end

  # Format a bank account as "Checking: XXXX 1234" or "Savings: XXXX 1234"
  def payment_source_display_name(%{type: "ba"} = source) do
    "#{String.capitalize(source.subtype)} Account: #{source.last_4}"
  end
end
