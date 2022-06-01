defmodule AppCount.Settings.Utils.CredentialSets do
  def credentials_for_provider(name) do
    case AppCount.Settings.CredentialSetRepo.get_by(provider: name) do
      nil ->
        {:error, :not_found}

      %{credentials: credentials} ->
        {:ok, Enum.into(credentials, %{}, fn cred -> {cred.name, cred.value} end)}
    end
  end

  def credentials_for_provider!(name) do
    case credentials_for_provider(name) do
      {:error, :not_found} -> raise "No credentials found for provider: #{name}"
      {:ok, credentials} -> credentials
    end
  end
end
