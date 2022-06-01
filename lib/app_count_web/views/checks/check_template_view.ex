defmodule AppCountWeb.Checks.CheckTemplateView do
  use AppCountWeb, :view

  def prepad(number, places \\ 6) do
    initial = "00000#{number}"
    String.slice(initial, String.length(initial) - places, String.length(initial) - 1)
  end

  def format_amount(nil), do: ""

  def format_amount(%Decimal{} = amount) do
    amount
    |> Decimal.to_float()
    |> :erlang.float_to_binary(decimals: 2)
    |> String.replace(~r/\B(?=(\d{3})+(?!\d))/, ",")
  end

  def format_amount(amount) do
    (amount / 1.0)
    |> :erlang.float_to_binary(decimals: 2)
    |> String.replace(~r/\B(?=(\d{3})+(?!\d))/, ",")
  end

  def date_formatter(date) do
    Timex.format!(date, "%m/%d/%Y", :strftime)
  end

  def invoice_date_formatter(date) do
    date = Date.from_iso8601!(date)
    Timex.format!(date, "%m/%d/%Y", :strftime)
  end

  def find_total(invoices) do
    Enum.reduce(invoices, 0, fn x, acc -> x["amount"] + acc end)
    |> format_amount
  end
end
