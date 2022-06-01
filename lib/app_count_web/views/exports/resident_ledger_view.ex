defmodule AppCountWeb.Exports.Residents.ResidentLedgerView do
  use AppCountWeb, :view
  use AppCount.Decimal

  def date_formatter(date) do
    case is_nil(date) do
      true -> ""
      _ -> Timex.format!(date, "%m/%d/%Y", :strftime)
    end
  end

  def address(address) do
    city = address["city"]
    state = address["state"]
    zip = address["zip"]
    "#{city}, #{state} #{zip}"
  end

  def get_type(row, type) do
    cond do
      row.type == type -> row.decimal
      true -> ""
    end
  end

  def accounting_format(amount) do
    cond do
      amount == "" -> ""
      Decimal.cmp(amount, 0) == :lt -> convert_num(amount)
      true -> amount
    end
  end

  defp convert_num(num) do
    string = num * -1
    "(#{string})"
  end
end
