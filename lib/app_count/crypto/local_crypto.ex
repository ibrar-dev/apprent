defmodule AppCount.Crypto.LocalCrypto do
  @moduledoc """
  We'll use AES encryption to encrypt data in the database. We do this instead of
  RSA encryption because we can trust ourselves as a source (whereas RSA is more
  for receiving information from untrusted sources or across uncontrolled channels).any()

  This module provides a pure functional core, and has no state of its own.

  There are no length constraints on text (other than those imposed by the system/language
  at large).
  """

  @doc """
  Given:
  - key (base-64-encoded AES256 key)
  - clear_text - any string

  Return {:ok, some_binary}

  where some_binary is the base-64-encoded binary representation of:

  {initialization_vector, encrypted_text}

  some_binary is fit to write to the DB and sufficient for decrypt
  """
  def encrypt(key, clear_text) when is_binary(clear_text) do
    decoded_key = decode_key(key)
    {:ok, {init_vector, cipher_text}} = ExCrypto.encrypt(decoded_key, clear_text)

    crypted_text =
      {init_vector, cipher_text}
      |> :erlang.term_to_binary()
      |> Base.url_encode64()

    {:ok, crypted_text}
  end

  def encrypt(key, clear_text) do
    try do
      encrypt(key, "#{clear_text}")
    rescue
      Protocol.UndefinedError ->
        {:error, "This data cannot be encoded"}
    end
  end

  @doc """
  decrypt/2 is the public interface - it takes a base64-encoded key and a
  base-64-encoded "packed" binary, then delegates the actual decryption.

  We base-64 encode the binary because some characters aren't representable
  within the SQL DB (it expects unicode, but we aren't always giving it unicode)

  Should return {:ok, "clear text"}

  When attempting to decode with the wrong (but still well-formed) key, we
  might possibly get incorrectly decoded text, usually represented as ""
  (an empty string). This seems to happen on 1% of attempts.

  We must leave open the possibility that we attempted to encode an empty string,
  and so we do not throw errors on this.

  The solution, of course, is proper key management.
  """
  def decrypt(key, packed_term) do
    try do
      decoded_key = decode_key(key)
      unpacked_term = Base.url_decode64!(packed_term, padding: false)
      {init_vector, cipher_text} = :erlang.binary_to_term(unpacked_term)
      decrypt(decoded_key, init_vector, cipher_text)
    rescue
      e -> {:error, "failed decrypt - #{e.message}"}
    end
  end

  def decrypt(decoded_key, init_vector, cipher_text) do
    result = ExCrypto.decrypt(decoded_key, init_vector, cipher_text)

    case result do
      {:ok, decrypted_binary} ->
        if String.valid?(decrypted_binary) do
          result
        else
          {:error, "failed decrypt"}
        end

      {:error, _argument_error} ->
        {:error, "failed decrypt"}
    end
  end

  # Our key is stored as a base64-encoded string. We want to decode.
  defp decode_key(key) do
    Base.url_decode64!(key, padding: false)
  end
end
