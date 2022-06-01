defmodule AppCount.EctoTypes.StringSet do
  use Ecto.Type

  def type, do: {:array, :string}

  def cast(list), do: {:ok, list}

  def load(list) do
    {:ok, MapSet.new(list)}
  end

  def dump(list) do
    {:ok, list}
  end
end
