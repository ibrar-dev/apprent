defmodule AppCount.Crypto.Crypted do
  use Ecto.Type
  alias AppCount.Crypto

  def type, do: :string

  def cast(plaintext) when is_binary(plaintext) do
    {:ok, Crypto.crypt(plaintext)}
  end

  def cast(int) when is_integer(int), do: cast("#{int}")

  def load(ciphered) do
    ret =
      case Crypto.decrypt(ciphered) do
        {:ok, ""} -> "failed decrypt"
        {:error, _} -> "failed decrypt"
        {:ok, plaintext} -> plaintext
      end

    {:ok, ret}
  end

  def dump("multi:" <> val) do
    {:ok, "multi:" <> val}
  end

  def dump(val) do
    case Base.decode64(val) do
      {:ok, _} -> {:ok, val}
      :error -> {:ok, Crypto.crypt(val)}
    end
  end

  def embed_as(_) do
    :dump
  end
end
