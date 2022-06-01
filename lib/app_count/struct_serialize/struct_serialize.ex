defmodule AppCount.StructSerialize do
  @moduledoc """
  Documentation for StructSerialize.
  """

  def serialize(%{__struct__: Ecto.Association.NotLoaded, __cardinality__: :one}) do
    nil
  end

  def serialize(%{__struct__: Ecto.Association.NotLoaded, __cardinality__: :many}) do
    []
  end

  def serialize(%Decimal{} = decimal) do
    Decimal.to_float(decimal)
  end

  def serialize(list) when is_list(list) do
    Enum.map(list, &serialize/1)
  end

  def serialize(%{__struct__: NaiveDateTime} = struct) do
    NaiveDateTime.to_string(struct)
  end

  def serialize(%{__struct__: Date} = struct) do
    Date.to_string(struct)
  end

  def serialize(%{__struct__: _} = struct) do
    struct
    |> Map.drop([:__meta__, :__struct__])
    |> serialize
  end

  def serialize(%{} = map) do
    map
    |> Map.to_list()
    |> Enum.map(fn {k, v} ->
      {k, serialize(v)}
    end)
    |> Map.new()
  end

  def serialize(v), do: v

  defmacro s_json(conn, struct) do
    quote do
      json(unquote(conn), serialize(unquote(struct)))
    end
  end
end
