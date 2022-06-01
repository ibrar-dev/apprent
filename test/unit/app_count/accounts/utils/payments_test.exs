defmodule AppCount.Accounts.Utils.PaymentsTest do
  use AppCount.DataCase
  alias AppCount.Accounts.Utils.Payments
  alias AppCount.Core.Clock

  @one_minute_short_of_12_hours 12 * 60 - 1

  setup do
    dates = %{
      now: Clock.now(),
      two_weeks_ago: Clock.now({-14, :days}) |> DateTime.to_naive(),
      ten_hours_ago: Clock.now({-600, :minutes}) |> DateTime.to_naive(),
      exactly_12_hours_ago: Clock.now({-720, :minutes}) |> DateTime.to_naive(),
      one_minute_short_of_12_hours_ago:
        Clock.now({-@one_minute_short_of_12_hours, :minutes}) |> DateTime.to_naive()
    }

    ~M[dates]
  end

  describe "payment_source_out_of_cooldown?/2" do
    test "returns false if lock date given is nil (nonexistent lock)" do
      lock_date = nil
      result = Payments.payment_source_in_cooldown?(lock_date)

      refute result
    end

    test "returns false if lock date given is more than 12 hours old", ~M[dates] do
      lock_date = dates.two_weeks_ago
      result = Payments.payment_source_in_cooldown?(lock_date)

      refute result
    end

    test "returns true if lock date given is less than 12 hours old", ~M[dates] do
      lock_date = dates.ten_hours_ago
      result = Payments.payment_source_in_cooldown?(lock_date)

      assert result
    end

    test "returns false if lock date is exactly 12 hours", ~M[dates] do
      lock_date = dates.exactly_12_hours_ago
      result = Payments.payment_source_in_cooldown?(lock_date)

      refute result
    end

    test "returns true if lock date is one minute short of 12 hours", ~M[dates] do
      lock_date = dates.one_minute_short_of_12_hours_ago
      result = Payments.payment_source_in_cooldown?(lock_date)

      assert result
    end
  end
end
