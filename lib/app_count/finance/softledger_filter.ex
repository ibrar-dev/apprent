defmodule AppCount.Finance.SoftLedgerFilter do
  @moduledoc """
  ref: https://api.softledger.com/docs#section/Filtering
  """

  alias AppCount.Finance.SoftLedgerFilter
  defstruct product: %{}, keys: []

  def new(softleddger_struct) do
    keys =
      softleddger_struct
      |> Map.from_struct()
      |> Map.keys()
      |> Enum.map(&Atom.to_string(&1))

    %SoftLedgerFilter{keys: keys}
  end

  def enum(filter, name, value) when is_list(value) do
    filter
    |> put(name, value, "$in")
  end

  def equal(filter, name, value) do
    filter
    |> put(name, value, "$eq")
  end

  def not_equal(filter, name, value) do
    filter
    |> put(name, value, "$ne")
  end

  def less_than_or_equal(filter, name, value) do
    filter
    |> put(name, value, "$lte")
  end

  def greater_than_or_equal(filter, name, value) do
    filter
    |> put(name, value, "$gte")
  end

  def greater_than(filter, name, value) do
    filter
    |> put(name, value, "$gt")
  end

  def less_than(filter, name, value) do
    filter
    |> put(name, value, "$lt")
  end

  defp put(%{product: product, keys: keys} = filter, name, value, op) do
    name = to_string(name)

    unless Enum.member?(keys, name) do
      raise "incorrect attribute: #{name}"
    end

    product =
      product
      |> Map.put(name, %{op => value})

    %{filter | product: product}
  end

  def express(%{product: product} = _filter) do
    product
  end
end
