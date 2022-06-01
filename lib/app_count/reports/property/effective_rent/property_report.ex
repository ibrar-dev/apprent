defmodule AppCount.Reports.Property.EffectiveRent.PropertyReport do
  use AppCount.Decimal

  def run(date, property_id) do
    AppCount.Reports.Property.EffectiveRent.run(date, property_id)
    |> process(date)
  end

  defp process(items, date) do
    Enum.map(items, &process_item(&1, date))
  end

  defp process_item(item, _date) do
    %{
      rent_amount: Enum.reduce(item.rent_amount, 0, &(&1["amount"] + &2))
    }
  end

  # unused ?
  # defp avg() do
  # end

  # unused ?
  # defp prorated_rent(rent, num_days, days_in_month), do: rent / days_in_month * num_days
end
