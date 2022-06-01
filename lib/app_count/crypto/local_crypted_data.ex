defmodule AppCount.Crypto.LocalCryptedData do
  @moduledoc """
  For values we generate (and store) locally (as opposed to ones we receive
  insecurely from other sources), we want to easily store them in their
  encrypted form and decrypt them on fetch as needed.

  This is a replacement for AppCount.Crypto.Crypted
  """
  alias AppCount.Crypto.LocalCryptoServer
  use Ecto.Type

  @doc """
  Part of Ecto.Type - this is the underlying data type.
  """
  def type() do
    :binary
  end

  @doc """
  Prepare plaintext data for encryption. Should return

  - {:ok, <<binary>>}
  - :error (no message)
  """
  def cast(data) do
    crypted = LocalCryptoServer.encrypt(data)

    case crypted do
      {:error, _message} -> :error
      _ -> crypted
    end
  end

  @doc """
  Make the cast data ready for DB entry.

  Returns:
  - {:ok, <<binary>>}
  - :error
  """
  def dump(value) when is_binary(value) do
    {:ok, value}
  end

  def dump(_) do
    :error
  end

  @doc """
  When used as an embedded schema field, we dump first.

  This lets us rely on the same unpacking behavior we'd see on a normal field.
  """
  def embed_as(_) do
    :dump
  end

  @doc """
  Load from DB and decrypt, assuming we can.

  Returns {:ok, nil} or {:ok, "some string"} or :error
  """
  def load(nil) do
    {:ok, nil}
  end

  def load("") do
    {:ok, ""}
  end

  def load(crypted) when is_binary(crypted) do
    result = LocalCryptoServer.decrypt(crypted)

    case result do
      {:error, _any} -> {:ok, "failed decrypt"}
      {:ok, message} -> {:ok, message}
    end
  end
end
