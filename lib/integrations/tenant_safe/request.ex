defmodule TenantSafe.Request do
  @endpoint "https://tenantsafe.instascreen.net/send/interchange"

  @spec submit(String.t()) :: {:ok, String.t()} | {:error, any}
  def submit(request) do
    case HTTPoison.post(@endpoint, request) do
      {:ok, %{status_code: 200, body: body}} -> {:ok, body}
      {:error, e} -> {:error, e.reason}
    end
  end
end
