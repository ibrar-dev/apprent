defmodule AppCount.Decimal.Float do
  defstruct value: 0.0

  def to_printable(%Decimal{} = d), do: %__MODULE__{value: Decimal.to_float(d)}
  def to_printable(d) when is_float(d), do: %__MODULE__{value: d}
  def to_printable(d) when is_integer(d), do: d

  defimpl String.Chars, for: __MODULE__ do
    def to_string(term) do
      :erlang.float_to_binary(term.value, [:compact, decimals: 10])
    end
  end
end
