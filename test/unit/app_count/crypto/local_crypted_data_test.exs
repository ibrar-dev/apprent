defmodule AppCount.Crypto.LocalCryptedDataTest do
  alias AppCount.Crypto.LocalCryptedData
  use AppCount.Case

  describe "type/0" do
    test "is binary" do
      assert LocalCryptedData.type() == :binary
    end
  end

  describe "cast/1" do
    test "encrypts string-representable data" do
      {:ok, result} = LocalCryptedData.cast("This is a message")
      assert is_binary(result)
    end

    test "encrypts nil" do
      assert {:ok, _result} = LocalCryptedData.cast(nil)
    end

    test "fails with unrepresentable types" do
      assert :error == LocalCryptedData.cast(%{foo: "bar"})
    end
  end

  describe "load/1" do
    test "loads crypted data" do
      {:ok, crypted} = LocalCryptedData.cast("secret message")

      assert {:ok, "secret message"} == LocalCryptedData.load(crypted)
    end

    test "fails to load others" do
      assert {:ok, "failed decrypt"} == LocalCryptedData.load("blah")
    end
  end

  describe "dump/1" do
    test "dumps a binary" do
      {:ok, result} = LocalCryptedData.cast("This is a message")

      assert {:ok, ^result} = LocalCryptedData.dump(result)
    end

    test "fails to dump others" do
      assert :error == LocalCryptedData.dump(123)
    end
  end
end
