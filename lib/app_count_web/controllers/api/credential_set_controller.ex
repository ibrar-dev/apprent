defmodule AppCountWeb.API.CredentialSetController do
  use AppCountWeb, :controller
  alias AppCount.Settings.CredentialSetRepo
  alias AppCount.Core.ClientSchema

  authorize(["Super Admin"])

  def index(conn, _params) do
    json(conn, CredentialSetRepo.list())
  end

  def create(conn, %{"credential_set" => params}) do
    CredentialSetRepo.insert(params)
    |> handle_error(conn)
  end

  def update(conn, %{"id" => id, "credential_set" => params}) do
    id
    |> String.to_integer()
    |> CredentialSetRepo.get()
    |> CredentialSetRepo.update(params)
    |> handle_error(conn)
  end

  def delete(conn, %{"id" => id}) do
    id =
      id
      |> String.to_integer()

    CredentialSetRepo.delete(ClientSchema.new(conn.assigns.client_schema, id))
    |> handle_error(conn)
  end
end
