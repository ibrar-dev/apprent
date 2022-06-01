defmodule AppCountWeb.AuthenticateAPIV1Plug do
  import Plug.Conn
  alias Phoenix.Controller

  @deps %{
    admin: AppCount.Admins.Admin,
    tokens: AppCount.Admins.Auth.Tokens
  }
  def init(default), do: default

  # TODO
  # 1. Remove Properties
  # 2. Single Sign On?
  def call(conn, _default) do
    with token when is_binary(token) <- get_token(conn),
         {:ok, %AppCountAuth.Users.Admin{} = admin, new_token} <- @deps.tokens.verify(token) do
      conn
      |> put_session(:admin_token, new_token)
      |> put_resp_cookie("admin_token", new_token, http_only: false)
      |> assign(:admin, admin)
      |> assign(:user, admin)
      |> assign(:admin_token, new_token)
      |> assign(:client_schema, admin.client_schema)
      |> assign(:roles, admin.roles)
    else
      _ ->
        conn
        |> put_status(401)
        |> Controller.json(%{error: "Authentication Failed"})
        |> halt
    end
  end

  def get_token(conn) do
    List.first(get_req_header(conn, "x-admin-token"))
  end
end
