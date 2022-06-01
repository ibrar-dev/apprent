defmodule AppCount.Crypto.LocalCryptoTest do
  use ExUnit.Case, async: true
  alias AppCount.Crypto.LocalCrypto

  setup do
    {:ok, key} = ExCrypto.generate_aes_key(:aes_256, :base64)
    message = "Sphinx of black quartz, judge my vow"

    %{key: key, message: message}
  end

  # Since encryption is non-deterministic, we have to assert on properties of
  # the result rather than the results themselves.
  describe "encrypt/2" do
    test "encrypts with valid key, cleartext", %{key: key, message: message} do
      assert {:ok, text} = LocalCrypto.encrypt(key, message)

      assert is_binary(text)

      assert {_init_vector, _crypted} =
               text
               |> Base.url_decode64!()
               |> :erlang.binary_to_term()
    end

    test "raises with non b64 key", %{message: message} do
      key = "foobarbaz"

      assert_raise ArgumentError, fn ->
        LocalCrypto.encrypt(key, message)
      end
    end

    test "raises with bad b64 key", %{message: message} do
      key = Base.encode64("foobarbaz")

      assert_raise MatchError, fn ->
        LocalCrypto.encrypt(key, message)
      end
    end

    test "handles non-binary cleartext representable as string", %{key: key} do
      message = 123_456.789

      assert {:ok, _something} = LocalCrypto.encrypt(key, message)
    end

    test "fails on non-string-representable clear-text", %{key: key} do
      message = %{hi: "how are you"}

      assert {:error, "This data cannot be encoded"} = LocalCrypto.encrypt(key, message)
    end
  end

  describe "decrypt/2" do
    test "decrypts successfully", %{key: key, message: message} do
      {:ok, crypted} = LocalCrypto.encrypt(key, message)

      assert {:ok, ^message} = LocalCrypto.decrypt(key, crypted)
    end

    test "decrypts successfully with a very long message", %{key: key} do
      message = String.duplicate("this is a very long message. ALALALALALA", 1000)

      {:ok, crypted} = LocalCrypto.encrypt(key, message)

      assert {:ok, ^message} = LocalCrypto.decrypt(key, crypted)
    end

    test "decrypts successfully with an empty string", %{key: key} do
      message = ""

      {:ok, crypted} = LocalCrypto.encrypt(key, message)

      assert {:ok, ""} = LocalCrypto.decrypt(key, crypted)
    end
  end
end
