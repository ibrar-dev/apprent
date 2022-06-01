defmodule AppCount.Maintenance.Utils.Auth do
  alias AppCount.Maintenance.Tech
  alias AppCount.Maintenance.TechRepo

  def cert_for_passcode(code) do
    with {:ok, _} <- UUID.info(code),
         %Tech{} = tech <- TechRepo.get_by_pass_code(code) do
      TechRepo.update(tech, %{pass_code: nil})
      {:ok, identifier_cert(tech.identifier), tech}
    else
      _ -> {:error, "Invalid Pass Code"}
    end
  end

  def authenticate_tech(cert) do
    result = AppCount.Crypto.LocalCryptoServer.decrypt(cert)

    case result do
      {:ok, identifier} ->
        TechRepo.get_by_identifier(identifier)

      {:error, message} ->
        {:error, message}
    end
  end

  defp identifier_cert(identifier) do
    result = AppCount.Crypto.LocalCryptoServer.encrypt(identifier)

    case result do
      {:ok, cert} ->
        cert

      {:error, message} ->
        {:error, message}
    end
  end
end
