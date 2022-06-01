defmodule AppCount.Messaging.BounceTest do
  use AppCount.DataCase
  alias AppCount.Messaging.Bounce
  @moduletag :bounce_test

  setup do
    valid = "someguy@test.com"
    invalid = "somerandomgibberish"
    ~M[valid, invalid]
  end

  describe "valid_email" do
    test "validate email works", ~M[valid] do
      res = Bounce.valid_email?(valid)

      assert res
    end

    test "invalid email returns false", ~M[invalid] do
      res = Bounce.valid_email?(invalid)

      assert !res
    end

    test "invalid non_binary email returns false" do
      res = Bounce.valid_email?(999)

      assert !res
    end
  end
end
