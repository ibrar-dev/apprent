defmodule AppCountWeb.AuthenticateAppPlug do
  import Plug.Conn
  alias Phoenix.Controller

  @deps %{
    accounts: AppCount.Accounts
  }

  def init(default), do: default

  def call(conn, _default) do
    with token when is_binary(token) <- get_token(conn),
         {:ok, %{} = user, _} <- @deps.accounts.verify_token(token) do
      conn
      |> assign(:user, user)
      |> assign(:client_schema, user.client_schema)
    else
      _ ->
        conn
        |> put_status(401)
        |> Controller.json(%{error: "Authentication Failed"})
        |> halt
    end
  end

  def get_token(conn) do
    List.first(get_req_header(conn, "x-user-token"))
  end
end
