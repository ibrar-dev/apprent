defmodule AppCountWeb.Helpers.Currency do
  def number_to_currency(%Decimal{exp: 0} = d) do
    "#{sign(d)}$#{delimit(d.coef)}.00"
  end

  def number_to_currency(%Decimal{} = d) do
    {dollars, cents} = String.split_at("#{d.coef}", d.exp)
    "#{sign(d)}$#{delimit(dollars)}.#{pad_cents(cents)}"
  end

  defp pad_cents(cents) do
    String.slice(cents, 0..1)
    |> String.pad_trailing(2, "0")
  end

  defp sign(%Decimal{sign: sign}) do
    "#{sign}"
    |> String.reverse()
    |> String.at(1)
  end

  defp delimit(num) do
    "#{num}"
    |> String.reverse()
    |> String.to_charlist()
    |> Enum.chunk_every(3)
    |> Enum.join(",")
    |> String.reverse()
  end
end
