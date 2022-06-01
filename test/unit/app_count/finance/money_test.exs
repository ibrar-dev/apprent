defmodule AppCount.Finance.MoneyTest do
  use AppCount.Case
  alias AppCount.Finance.Money

  describe "amount_as_string" do
    test "1000" do
      result = Money.amount_as_string(1000)
      assert result == "10.00"
    end

    test "10" do
      result = Money.amount_as_string(10)
      assert result == "0.10"
    end

    test "1" do
      result = Money.amount_as_string(1)
      assert result == "0.01"
    end
  end
end
