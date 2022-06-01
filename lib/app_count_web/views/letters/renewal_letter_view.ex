defmodule AppCountWeb.Letters.RenewalLetterView do
  use AppCountWeb, :view
  use AppCount.Decimal

  def residents(residents) do
    Enum.reduce(residents, "", fn r, acc -> "#{acc} #{r["first_name"]} #{r["last_name"]}," end)
  end

  def date_formatter(), do: date_formatter(AppCount.current_time())

  def date_formatter(date) do
    Timex.format!(date, "%m/%d/%Y", :strftime)
  end

  def default_features(features) do
    case length(features) do
      0 -> []
      _ -> Enum.filter(features, fn f -> f["default_charge"] end)
    end
  end

  def mtm_total(mr, features) do
    features_total = Enum.reduce(features, 0, fn f, total -> f["price"] + total end)
    mr + features_total
  end

  def calculate_rent(pack, mr, charges) do
    cond do
      pack.base == "Current Rent" -> calculate_current_rent(pack, charges)
      true -> calculate_mr_rent(pack, mr)
    end
  end

  def calculate_total(pack, mr, charges, features) do
    rent_total = calculate_rent(pack, mr, charges)
    Enum.reduce(features, rent_total, fn f, total -> f["price"] + total end)
  end

  def calculate_custom_total(pack, features) do
    Enum.reduce(features, pack.amount, fn f, total -> f["price"] + total end)
  end

  defp calculate_current_rent(pack, charges) do
    rent_amount = Enum.find(charges, fn c -> c["account"] == "Rent" end)

    cond do
      pack.dollar -> calculate_dollar(pack, rent_amount["amount"])
      true -> calculate_percentage(pack, rent_amount["amount"])
    end
  end

  defp calculate_dollar(pack, amount) do
    pack.amount + amount
  end

  defp calculate_percentage(pack, amount) do
    amount + amount * (pack.amount / 100)
  end

  defp calculate_mr_rent(pack, amount) do
    cond do
      pack.dollar -> calculate_dollar(pack, amount)
      true -> calculate_percentage(pack, amount)
    end
  end
end

## base + (base * (percentage / 100))
