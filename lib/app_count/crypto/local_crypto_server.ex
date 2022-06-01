defmodule AppCount.Crypto.LocalCryptoServer do
  alias AppCount.Crypto.LocalCrypto

  @moduledoc """
  The Crypto-Server's job is to hold on to cryptographic keys (for AES
  encryption) and to then encrypt/decrypt using those keys and provided args.

  It could run as a stateful process in the future, but for now does not need to.
  """

  @doc """
  Load local crypto key from Env. In the future we may wish to extract this.

  This key should be a base-64-encoded AES-256 key. To generate:

  {:ok, key} = ExCrypto.generate_aes_key(:aes_256, :base64)
  """
  def crypto_key() do
    AppCount.env()[:local_crypto_key]
  end

  @doc """
  Given the loaded crypto key, encrypt clear text.

  Will return:
  - {:ok, crypted}
  - {:error, "some message"}
  """
  def encrypt(clear_text) do
    LocalCrypto.encrypt(crypto_key(), clear_text)
  end

  @doc """
  Given ciphered text, will use loaded key to decrypt.

  Returns:
  - {:ok, "clear text"}
  - {:error, "some message}
  """
  def decrypt(cipher_text) do
    try do
      LocalCrypto.decrypt(crypto_key(), cipher_text)
    rescue
      e ->
        {:error, "Decryption error! #{Exception.format(:error, e, __STACKTRACE__)}"}
    end
  end

  @doc """
  Sometimes we just need the decrypted string back, instead of an OK tuple.
  """
  def decrypt!(cipher_text) do
    {:ok, clear_text} = decrypt(cipher_text)

    clear_text
  end
end
