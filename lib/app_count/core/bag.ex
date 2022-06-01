defmodule AppCount.Core.Bag do
  @moduledoc """
  Bag is a data structure you can use for counting objects.
  You can have one or more occurrences or a particular item in no particular order.
  A Bag is unordered like a Set, but allows duplicates.
  """
  alias AppCount.Core.Bag
  defstruct content: %{}

  def new do
    %Bag{}
  end

  def add(%Bag{content: content} = bag, item) do
    prev_count = count(bag, item)
    content = Map.put(content, item, prev_count + 1)
    %Bag{content: content}
  end

  def size(%Bag{content: content}) do
    map_size(content)
  end

  def count(%Bag{content: content}, item) do
    Map.get(content, item, 0)
  end

  def max(%Bag{content: map}) when map_size(map) == 0 do
    []
  end

  def max(%Bag{} = bag) do
    highest_count = highest_count(bag)

    bag
    |> Enum.reduce([], fn {item, count}, acc ->
      if count == highest_count do
        [item | acc]
      else
        acc
      end
    end)
  end

  def highest_count(bag) do
    bag
    |> Enum.reduce(0, fn {_item, count}, max ->
      if count > max do
        count
      else
        max
      end
    end)
  end

  def shift(%Bag{content: content}) when map_size(content) == 0 do
    :error
  end

  def shift(%Bag{content: content}) do
    [item | _] = Map.keys(content)
    {item_count, new_content} = Map.pop(content, item)
    {:ok, {item, item_count}, %Bag{content: new_content}}
  end

  defimpl Enumerable do
    alias AppCount.Core.Bag

    @impl Enumerable
    def count(%Bag{}) do
      {:error, __MODULE__}
    end

    @impl Enumerable
    def member?(_bag, _item) do
      {:error, __MODULE__}
    end

    @impl Enumerable
    def reduce(array, acc, fun)

    def reduce(%Bag{} = bag, {:cont, acc}, fun) do
      case Bag.shift(bag) do
        {:ok, item_and_count, new_bag} ->
          reduce(new_bag, fun.(item_and_count, acc), fun)

        :error ->
          {:done, acc}
      end
    end

    def reduce(_bag, {:halt, acc}, _fun) do
      {:halted, acc}
    end

    def reduce(bag, {:suspend, acc}, fun) do
      {:suspended, acc, &reduce(bag, &1, fun)}
    end

    @impl Enumerable
    def slice(_bag) do
      {:error, __MODULE__}
    end
  end
end
