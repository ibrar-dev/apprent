defmodule AppCount.Jobs.ArgList do
  use Ecto.Type

  def type, do: :map

  def cast(list) when is_list(list), do: {:ok, %{json: list}}

  def load(json), do: {:ok, json}

  def dump(list) when is_list(list), do: {:ok, list}
  def dump(%{json: list}) when is_list(list), do: {:ok, list}
end
