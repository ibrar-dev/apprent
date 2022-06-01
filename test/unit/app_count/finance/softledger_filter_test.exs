defmodule AppCount.Finance.SoftLedgerFilterTest do
  @moduledoc """
  ref: https://api.softledger.com/docs#section/Filtering
  """

  use AppCount.Case
  alias AppCount.Finance.SoftLedgerFilter

  defmodule Filterable do
    defstruct _id: :not_set,
              amount: :not_set,
              number: :not_set,
              status: :not_set
  end

  test "new" do
    # When
    result = SoftLedgerFilter.new(Filterable)
    assert %SoftLedgerFilter{} = result
    assert result.keys == ["_id", "amount", "number", "status"]
  end

  test "error incorrect attr name" do
    filter = SoftLedgerFilter.new(Filterable)
    # When
    assert_raise RuntimeError, "incorrect attribute: not_an_attr", fn ->
      SoftLedgerFilter.equal(filter, :not_an_attr, 100)
    end
  end

  test "status enum of [created, approved] " do
    filter = SoftLedgerFilter.new(Filterable)
    # When
    filter = SoftLedgerFilter.enum(filter, :status, ["created", "approved"])

    assert SoftLedgerFilter.express(filter) ==
             %{
               "status" => %{
                 "$in" => ["created", "approved"]
               }
             }
  end

  test "amount equal 100" do
    filter = SoftLedgerFilter.new(Filterable)
    # When
    filter = SoftLedgerFilter.equal(filter, :amount, 100)

    assert SoftLedgerFilter.express(filter) ==
             %{
               "amount" => %{
                 "$eq" => 100
               }
             }
  end

  test "amount not_equal 100" do
    filter = SoftLedgerFilter.new(Filterable)
    # When
    filter = SoftLedgerFilter.not_equal(filter, :amount, 100)

    assert SoftLedgerFilter.express(filter) ==
             %{
               "amount" => %{
                 "$ne" => 100
               }
             }
  end

  test "amount less_than_or_equal 100" do
    filter = SoftLedgerFilter.new(Filterable)
    # When
    filter = SoftLedgerFilter.less_than_or_equal(filter, :amount, 100)

    assert SoftLedgerFilter.express(filter) ==
             %{
               "amount" => %{
                 "$lte" => 100
               }
             }
  end

  test "amount greater_than_or_equal 100" do
    filter = SoftLedgerFilter.new(Filterable)
    # When
    filter = SoftLedgerFilter.greater_than_or_equal(filter, :amount, 100)

    assert SoftLedgerFilter.express(filter) ==
             %{
               "amount" => %{
                 "$gte" => 100
               }
             }
  end

  test "amount greater_than 100" do
    filter = SoftLedgerFilter.new(Filterable)
    # When
    filter = SoftLedgerFilter.greater_than(filter, :amount, 100)

    assert SoftLedgerFilter.express(filter) ==
             %{
               "amount" => %{
                 "$gt" => 100
               }
             }
  end

  test "amount less_than 100" do
    filter = SoftLedgerFilter.new(Filterable)
    # When
    filter = SoftLedgerFilter.less_than(filter, :amount, 100)

    assert SoftLedgerFilter.express(filter) ==
             %{
               "amount" => %{
                 "$lt" => 100
               }
             }
  end

  test "number greater_than 200" do
    filter = SoftLedgerFilter.new(Filterable)
    # When
    filter = SoftLedgerFilter.greater_than(filter, :number, 200)

    assert SoftLedgerFilter.express(filter) ==
             %{
               "number" => %{
                 "$gt" => 200
               }
             }
  end

  test "both number greater_than 200 and amount greater_than 100" do
    filter = SoftLedgerFilter.new(Filterable)
    # When
    filter =
      filter
      |> SoftLedgerFilter.greater_than(:number, 200)
      |> SoftLedgerFilter.greater_than(:amount, 100)

    assert SoftLedgerFilter.express(filter) ==
             %{
               "number" => %{
                 "$gt" => 200
               },
               "amount" => %{
                 "$gt" => 100
               }
             }
  end

  test "both number less_than 200 and amount greater_than 100" do
    filter = SoftLedgerFilter.new(Filterable)
    # When
    filter =
      filter
      |> SoftLedgerFilter.less_than(:number, 200)
      |> SoftLedgerFilter.greater_than(:amount, 100)

    assert SoftLedgerFilter.express(filter) ==
             %{
               "number" => %{
                 "$lt" => 200
               },
               "amount" => %{
                 "$gt" => 100
               }
             }
  end
end
