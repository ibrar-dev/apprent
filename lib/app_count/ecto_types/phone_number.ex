defmodule AppCount.EctoTypes.PhoneNumber do
  use Ecto.Type

  def type, do: :string

  def cast(number), do: {:ok, number}

  def load(number) do
    {:ok, format_phone(number)}
  end

  def dump(number), do: wrap_ok(minimize(number))

  def format_phone(
        <<area::binary-size(3)>> <> <<prefix::binary-size(3)>> <> <<suffix::binary-size(4)>>
      ) do
    "(#{area})#{prefix}-#{suffix}"
  end

  def minimize(number) do
    case String.replace(number, ~r/[^\d]/, "") do
      str when byte_size(str) == 10 -> str
      _ -> {:error, :invalid_length}
    end
  end

  defp wrap_ok({:error, _} = e), do: e
  defp wrap_ok(r), do: {:ok, r}
end
