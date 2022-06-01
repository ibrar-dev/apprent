defmodule AppCountWeb.AuthenticatePlug do
  import Plug.Conn
  use AppCountWeb, :controller
  alias AppCount.Core.ClientSchema

  @deps %{
    admin: AppCount.Admins.Admin,
    tokens: AppCount.Admins.Auth.Tokens,
    properties: AppCount.Properties
  }
  def init(default), do: default

  def call(conn, _default) do
    with token when is_binary(token) <- get_token(conn),
         {:ok, %AppCountAuth.Users.Admin{} = admin, new_token} <- @deps.tokens.verify(token),
         {:ok, %AppCountAuth.Users.Admin{} = admin, new_token} <-
           check_user_status(admin, new_token) do
      properties =
        ClientSchema.new(admin)
        |> @deps.properties.list_properties(:min)
        |> Poison.encode!()

      conn
      |> put_session(:admin_token, new_token)
      |> put_resp_cookie("admin_token", new_token, http_only: false)
      |> assign(:admin, admin)
      |> assign(:user, admin)
      |> assign(:admin_token, new_token)
      |> assign(:roles, admin.roles)
      |> assign(:properties, properties)
      |> assign(:client_schema, admin.client_schema)
    else
      {:error, :forced_logout} ->
        conn
        |> put_session(:admin_token, "forced_logout")
        |> put_resp_cookie("admin_token", "forced_logout", http_only: false)
        |> Phoenix.Controller.redirect(to: AppCountWeb.Router.Helpers.session_path(conn, :new))
        |> halt

      _ ->
        conn
        |> Phoenix.Controller.redirect(to: AppCountWeb.Router.Helpers.session_path(conn, :new))
        |> halt
    end
  end

  def check_user_status(%AppCountAuth.Users.Admin{} = admin, new_token) do
    case AppCountAuth.AuthServer.get_status(admin) do
      :pass ->
        {:ok, admin, new_token}

      :refresh ->
        admin = AppCount.Public.Auth.refresh_user(admin)
        {:ok, admin, AppCountWeb.Token.token(admin)}

      :logout ->
        {:error, :forced_logout}

      :block ->
        {:error, :blocked}
    end
  end

  def get_token(conn) do
    get_session(conn, :admin_token) || List.first(get_req_header(conn, "x-admin-token"))
  end
end
