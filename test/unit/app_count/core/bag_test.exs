defmodule AppCount.Core.BagTest do
  use AppCount.DataCase

  alias AppCount.Core.Bag

  setup do
    bag = Bag.new()
    ~M[bag]
  end

  test "new" do
    assert Bag.new() == %Bag{}
  end

  describe "shift/1" do
    test "empty", ~M[bag] do
      assert :error == Bag.shift(bag)
    end

    test "one item", ~M[bag] do
      bag = Bag.add(bag, "thing")

      # When
      result = Bag.shift(bag)
      assert {:ok, {item, item_count}, new_bag} = result
      assert item == "thing"
      assert item_count == 1
      assert new_bag == %Bag{}
    end

    test "two items, same count", ~M[bag] do
      bag =
        bag
        |> Bag.add("thingOne")
        |> Bag.add("thingTwo")

      # When
      result = Bag.shift(bag)
      assert {:ok, {item, item_count}, new_bag} = result
      assert item == "thingOne"
      assert item_count == 1
      assert Enum.count(new_bag) == 1
    end
  end

  describe "Enum reduce/3" do
    test "empty", ~M[bag] do
      result = Enum.reduce(bag, [], fn {item, _count}, acc -> [item | acc] end)
      assert result == []
    end

    test "one item", ~M[bag] do
      bag = Bag.add(bag, "thing")

      result = Enum.reduce(bag, [], fn {item, _count}, acc -> [item | acc] end)
      assert result == ["thing"]
    end

    test "two items", ~M[bag] do
      bag =
        bag
        |> Bag.add("thingOne")
        |> Bag.add("thingTwo")

      result = Enum.reduce(bag, [], fn {item, _count}, acc -> [item | acc] end)
      assert result == ["thingTwo", "thingOne"]
    end
  end

  describe "Enum member?/2" do
    test "empty", ~M[bag] do
      refute Enum.member?(bag, "NOPE")
    end

    test "one item", ~M[bag] do
      bag = Bag.add(bag, "thing")

      Enum.member?(bag, "thing")
    end
  end

  describe " Enum count/1" do
    test "empty", ~M[bag] do
      assert Enum.empty?(bag)
    end

    test "one item", ~M[bag] do
      bag = Bag.add(bag, "thing")

      assert 1 == Enum.count(bag)
    end

    test "two items", ~M[bag] do
      bag =
        bag
        |> Bag.add("thingOne")
        |> Bag.add("thingTwo")

      assert 2 == Enum.count(bag)
    end
  end

  describe "bag exists, max/1" do
    test "empty", ~M[bag] do
      assert [] == Bag.max(bag)
    end

    test "one item", ~M[bag] do
      bag = Bag.add(bag, "thing")

      assert ["thing"] == Bag.max(bag)
    end

    test "two items, same count", ~M[bag] do
      bag =
        bag
        |> Bag.add("thingOne")
        |> Bag.add("thingTwo")

      assert ["thingTwo", "thingOne"] == Bag.max(bag)
    end

    test "two items, thingTwo added twice", ~M[bag] do
      bag =
        bag
        |> Bag.add("thingOne")
        |> Bag.add("thingTwo")
        |> Bag.add("thingTwo")

      assert ["thingTwo"] == Bag.max(bag)
    end

    test "two items, thingOne added twice", ~M[bag] do
      bag =
        bag
        |> Bag.add("thingOne")
        |> Bag.add("thingOne")
        |> Bag.add("thingTwo")

      assert ["thingOne"] == Bag.max(bag)
    end
  end

  describe "highest_count" do
    test "empty", ~M[bag] do
      assert [] == Bag.max(bag)
    end

    test "one item", ~M[bag] do
      bag = Bag.add(bag, "thing")
      max = Bag.highest_count(bag)
      assert 1 == max
    end

    test "two items, same count", ~M[bag] do
      bag =
        bag
        |> Bag.add("thingOne")
        |> Bag.add("thingTwo")

      max = Bag.highest_count(bag)
      assert 1 == max
    end

    test "two items, thingTwo added twice", ~M[bag] do
      bag =
        bag
        |> Bag.add("thingOne")
        |> Bag.add("thingTwo")
        |> Bag.add("thingTwo")

      max = Bag.highest_count(bag)
      assert 2 == max
    end

    test "two items, thingOne added twice", ~M[bag] do
      bag =
        bag
        |> Bag.add("thingOne")
        |> Bag.add("thingOne")
        |> Bag.add("thingTwo")

      assert ["thingOne"] == Bag.max(bag)
    end
  end

  describe "bag exists" do
    test "item count when empty", ~M[bag] do
      assert Bag.count(bag, "thing") == 0
    end

    test "add one", ~M[bag] do
      result = Bag.add(bag, "thing")
      # Then
      assert Bag.size(result) == 1
      assert Bag.count(result, "thing") == 1
    end

    test "add two different", ~M[bag] do
      result =
        bag
        |> Bag.add("thing01")
        |> Bag.add("thing02")

      assert Bag.size(result) == 2
    end

    test "add two same", ~M[bag] do
      result =
        bag
        |> Bag.add("thing")
        |> Bag.add("thing")

      assert Bag.size(result) == 1
    end

    test "count/2 after add two same", ~M[bag] do
      result =
        bag
        |> Bag.add("thing")
        |> Bag.add("thing")

      assert Bag.count(result, "thing") == 2
    end
  end
end
