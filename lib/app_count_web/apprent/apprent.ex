defmodule AppCountWeb.AppRent do
  def decrypt(cipher_text) do
    %{secret: secret, sign: sign} = AppCount.env(:apprent_crypt)
    Plug.Crypto.MessageEncryptor.decrypt(cipher_text, secret, sign)
  end

  def decrypt!(cipher_text) do
    case decrypt(cipher_text) do
      {:ok, decrypted} -> decrypted
      _ -> raise "Bad Decrypt"
    end
  end
end
