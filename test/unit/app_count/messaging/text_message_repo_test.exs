defmodule AppCount.Messaging.TextMessageRepoTest do
  use AppCount.DataCase
  alias AppCount.Messaging.TextMessageRepo

  setup do
    valid_params = %{
      direction: "outgoing",
      from_number: "123",
      to_number: "321"
    }

    ~M[valid_params]
  end

  test "create/1", ~M[valid_params] do
    {:ok, res} =
      valid_params
      |> TextMessageRepo.create()

    assert res.direction == valid_params.direction
    assert res.from_number == valid_params.from_number
    assert res.to_number == valid_params.to_number
  end

  describe "format_number/2" do
    test "normal passes no country code" do
      original = "1234567890"
      res = AppCount.Messaging.TextMessageRepo.format_number(original, :no_country_code)

      assert res == original
    end

    test "normal passes country code" do
      original = "1234567890"
      res = AppCount.Messaging.TextMessageRepo.format_number(original, :country_code)

      assert res == "+1" <> original
    end

    test "normal human entry no country code" do
      original = "(123) 456-7890"
      res = AppCount.Messaging.TextMessageRepo.format_number(original, :no_country_code)

      assert res == "1234567890"
    end

    test "normal human entry country code" do
      original = "(123) 456-7890"
      res = AppCount.Messaging.TextMessageRepo.format_number(original, :country_code)

      assert res == "+11234567890"
    end

    test "janky human entry country code" do
      original = "123.456-7890lorumipsum"
      res = AppCount.Messaging.TextMessageRepo.format_number(original, :country_code)

      assert res == "+11234567890"
    end
  end
end
