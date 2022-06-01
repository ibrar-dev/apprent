defmodule AppCountWeb.API.TechAuthController do
  use AppCountWeb, :controller

  def create(conn, %{"code" => code}) do
    case AppCount.Maintenance.cert_for_passcode(code) do
      {:ok, cert, tech} ->
        conn
        |> json(%{
          cert: cert,
          id: tech.id
        })

      {:error, error} ->
        json(conn, %{error: error})
    end
  end
end
