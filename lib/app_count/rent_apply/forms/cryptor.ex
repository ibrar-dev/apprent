defmodule AppCount.RentApply.Forms.Cryptor do
  def generate_pin do
    binary = :crypto.strong_rand_bytes(4)

    :lists.flatten(for b <- :erlang.binary_to_list(binary), do: :io_lib.format("~2.36.0B", [b]))
    |> List.to_string()
  end

  def encrypt(%{} = map, pin) do
    Poison.encode!(map)
    |> encrypt(pin)
  end

  def encrypt(phrase, pin) do
    [key, iv] = keys(pin)

    # boolean refers to encryption. True = encrypt/ false = decrypt
    :crypto.crypto_one_time(:aes_256_cbc, key, iv, pad(phrase), true)
    |> Base.encode64()
  end

  def decrypt(data, pin) do
    [key, iv] = keys(pin)
    decoded = Base.decode64!(data)

    # boolean refers to encryption. True = encrypt/ false = decrypt
    :crypto.crypto_one_time(:aes_256_cbc, key, iv, decoded, false)
    |> depad
  end

  defp generate_key(phrase) do
    :crypto.hash(:sha512, phrase)
    |> hexdigest
    |> String.slice(0, 32)
  end

  defp hexdigest(binary) do
    :lists.flatten(for b <- :erlang.binary_to_list(binary), do: :io_lib.format("~2.16.0B", [b]))
    |> :string.to_lower()
    |> List.to_string()
  end

  defp pad(str, block_size \\ 32) do
    len = byte_size(str)
    # UTF chars are 2byte, ljust counts only 1
    utfs = len - String.length(str)
    pad_len = block_size - rem(len, block_size) - utfs
    # PKCS#7 padding
    String.pad_trailing(str, len + pad_len, " ")
  end

  defp depad(str) do
    # this weird pattern match is to resolve situations where the last char is actually multiple bytes
    [last | _] =
      String.last(str)
      |> :erlang.binary_to_list()

    String.replace_trailing(str, <<last::utf8>>, "")
  end

  defp keys(pin) do
    iv =
      AppCount.env(:forms_iv)
      |> String.slice(0, 16)

    key = generate_key(pin)
    [key, iv]
  end
end
