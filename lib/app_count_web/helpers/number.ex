defmodule AppCountWeb.Helpers.Number do
  def format_number(%Decimal{exp: 0} = d) do
    "#{sign(d)}#{delimit(d.coef)}"
  end

  def format_number(%Decimal{} = d) do
    {dollars, cents} = String.split_at("#{d.coef}", d.exp)
    "#{sign(d)}#{delimit(dollars)}.#{cents}"
  end

  def format_number(d), do: format_number(Decimal.new(d))

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
