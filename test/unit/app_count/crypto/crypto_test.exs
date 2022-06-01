defmodule AppCount.Crypto.CryptoCase do
  use ExUnit.Case
  alias AppCount.Crypto
  @moduletag :crypto

  test "can encrypt and decrypt short text" do
    short_text = "hello world, this is a short message that will be mangled and then unmangled"
    cipher = Crypto.crypt(short_text)

    assert is_binary(cipher)
    assert byte_size(cipher) == 344

    {:ok, msg} = Crypto.decrypt(cipher)

    assert msg == short_text
  end

  test "can encrypt and decrypt large text blocks" do
    long_text =
      "Majorly long text block, at least once multiplied."
      |> String.duplicate(8)

    cipher = Crypto.crypt(long_text)

    assert is_binary(cipher)
    assert String.starts_with?(cipher, "multi:")

    {:ok, msg} = Crypto.decrypt(cipher)
    assert msg == long_text
  end
end
