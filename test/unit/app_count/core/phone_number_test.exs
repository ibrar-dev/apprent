defmodule AppCount.Core.PhoneNumberTest do
  use AppCount.Case, async: true
  alias AppCount.Core.PhoneNumber

  describe "new/1" do
    test "human number" do
      phone = PhoneNumber.new("(555) 123-4567")
      assert "+15551234567" == PhoneNumber.dial_string(phone)
    end
  end

  describe "dial_string/1" do
    test "valid number w/o +1 (america country code)" do
      phone = PhoneNumber.new("1231231234")
      assert "+11231231234" == PhoneNumber.dial_string(phone)
    end

    test "invalid number w/o +1 (america country code)" do
      phone = PhoneNumber.new("9")
      assert "Invalid Number: +19" == PhoneNumber.dial_string(phone)
    end

    test "valid number already has +1" do
      phone = PhoneNumber.new("+11231231234")
      assert "+11231231234" == PhoneNumber.dial_string(phone)
    end

    test "invalid number already has +1" do
      phone = PhoneNumber.new("+12")
      assert "Invalid Number: +12" == PhoneNumber.dial_string(phone)
    end

    test "dial_string invalid number" do
      phone = PhoneNumber.new(nil)
      assert "Invalid Number: nil" == PhoneNumber.dial_string(phone)
    end
  end

  describe "valid?()" do
    test "valid number already has +1" do
      phone = PhoneNumber.new("+11231231234")
      assert PhoneNumber.valid?(phone)
    end

    test "valid number w/o  +1" do
      phone = PhoneNumber.new("1231231234")
      assert PhoneNumber.valid?(phone)
    end

    test "too short" do
      phone = PhoneNumber.new("1234")
      refute PhoneNumber.valid?(phone)
    end

    test "too long" do
      phone = PhoneNumber.new("12345789012345")
      refute PhoneNumber.valid?(phone)
    end

    test "nil " do
      no_phone = PhoneNumber.new(nil)
      assert %PhoneNumber{number: nil} = no_phone
    end

    test "valid?(nil) " do
      no_phone = PhoneNumber.new(nil)
      refute PhoneNumber.valid?(no_phone)
    end
  end
end
