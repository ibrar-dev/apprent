defmodule AppCount.Crypto do
  require Logger
  @public_exp 65537
  @max_length_for_RSA_encrypt 245

  def crypt(text) when byte_size(text) > @max_length_for_RSA_encrypt do
    msg =
      chunk_message(text)
      |> Enum.map(&crypt/1)
      |> Enum.join("~~~")

    "multi:" <> msg
  end

  def crypt(text) do
    text
    |> :public_key.encrypt_public({:RSAPublicKey, public_modulus(), @public_exp})
    |> Base.encode64()
  end

  def decrypt("multi:" <> multi_cipher) do
    multi_cipher
    |> String.split("~~~")
    |> Enum.reduce_while({:ok, ""}, fn cipher_part, {_, decrypted} ->
      case decrypt(cipher_part) do
        {:ok, part} -> {:cont, {:ok, decrypted <> part}}
        e -> {:halt, e}
      end
    end)
  end

  def decrypt(cipher) when is_binary(cipher) do
    case HTTPoison.post(path(), Poison.encode!(%{cipher: cipher})) do
      {:ok, %{body: body}} ->
        {:ok, body}

      {:error, %{reason: :econnrefused}} ->
        start_crypto_server()

        decrypt(cipher)

      {:error, error} ->
        {:error, error}
    end
  end

  def decrypt!(cipher) when is_binary(cipher) do
    case decrypt(cipher) do
      {:ok, info} -> info
      _ -> raise "Decryption Error"
    end
  end

  def start_crypto_server do
    Task.async(fn ->
      try do
        System.cmd("killall", ["crypto"])
      rescue
        _ -> System.cmd("pkill", ["crypto"])
      end

      exec_path = AppCount.env()[:crypto_server_path]
      Port.open({:spawn_executable, exec_path}, [:binary, :use_stdio, :exit_status])
      listen_crypto()
    end)
    |> Task.await()
  end

  defp listen_crypto do
    receive do
      {_port, {:data, "Starting Server"}} ->
        initialize_crypto_server()

      msg ->
        Logger.error(inspect(msg))
        listen_crypto()
    end
  end

  defp initialize_crypto_server do
    HTTPoison.post(path(), Poison.encode!(%{key: public_modulus()}))
  end

  defp chunk_message(text) do
    text
    |> String.codepoints()
    |> Enum.chunk_every(@max_length_for_RSA_encrypt)
    |> Enum.map(&Enum.join/1)
  end

  defp path do
    "http+unix://#{AppCount.env()[:socket_path]}"
  end

  defp public_modulus do
    AppCount.env()[:rent_apply_key]
  end
end
