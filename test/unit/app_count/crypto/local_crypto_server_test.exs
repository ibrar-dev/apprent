defmodule AppCount.Crypto.LocalCryptoServerTest do
  use AppCount.Case
  alias AppCount.Crypto.LocalCryptoServer

  describe "crypto_key/0" do
    test "fetches" do
      result = LocalCryptoServer.crypto_key()
      assert is_binary(result)
    end
  end

  describe "encrypt/1" do
    test "encrypts successfully" do
      assert {:ok, crypted} = LocalCryptoServer.encrypt("This is a message")
      assert is_binary(crypted)
    end
  end

  describe "decrypt/1" do
    test "decrypts successfully" do
      {:ok, crypted} = LocalCryptoServer.encrypt("I'm a little teapot")

      assert {:ok, "I'm a little teapot"} = LocalCryptoServer.decrypt(crypted)
    end
  end

  describe "decrypt!/1" do
    test "decrypts successfully" do
      {:ok, crypted} = LocalCryptoServer.encrypt("I'm a little teapot")

      assert "I'm a little teapot" = LocalCryptoServer.decrypt!(crypted)
    end

    test "raises on failure" do
      assert_raise MatchError, fn ->
        LocalCryptoServer.decrypt!("foobarbaz")
      end
    end
  end
end
