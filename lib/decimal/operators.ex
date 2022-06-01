defmodule AppCount.Decimal.Operators do
  import Decimal

  def left - right do
    sub(convert!(left), convert!(right))
    |> convert_result
  end

  def left + right when is_list(left) and (is_list(right) or is_nil(right)) do
    left
    |> Enum.with_index()
    |> Enum.map(fn {value, index} ->
      add(convert!(value), convert!(Enum.at(right || [], index)))
      |> convert_result
    end)
  end

  def left + right do
    add(convert!(left), convert!(right))
    |> convert_result
  end

  def left * right do
    mult(convert!(left), convert!(right))
    |> convert_result
  end

  def left / right do
    Decimal.div(convert!(left), convert!(right))
    |> convert_result
  end

  def to_decimal(%Decimal{} = d), do: d
  def to_decimal(d) when is_integer(d), do: Decimal.new(d)
  def to_decimal(d) when is_float(d), do: Decimal.from_float(d)
  def to_decimal(d) when is_binary(d), do: Decimal.new(d)

  defp convert_result(%Decimal{exp: exp} = res) when exp < 0, do: to_float(res)
  defp convert_result(res), do: to_integer(res)
  defp convert!(%Decimal{} = d), do: d
  defp convert!(num) when is_float(num), do: Decimal.from_float(num)
  defp convert!(num), do: Decimal.new(num || 0)

  def to_decimal_indifferent(num) when is_binary(num) do
    case String.contains?(num, ".") do
      true ->
        String.to_float(num)
        |> to_decimal

      _ ->
        String.to_integer(num)
        |> to_decimal
    end
  end

  def to_decimal_indifferent(num) when is_nil(num), do: Decimal.new(0)
  def to_decimal_indifferent(num), do: to_decimal(num)

  def decimal_to_string(num) do
    if Decimal.is_decimal(num) do
      Decimal.to_string(num)
    else
      num
    end
  end
end
