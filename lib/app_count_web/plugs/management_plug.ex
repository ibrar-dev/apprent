defmodule AppCountWeb.ManagementPlug do
  import Plug.Conn
  use AppCountWeb, :controller

  @deps %{
    admin: AppCount.Admins.Admin,
    tokens: AppCount.Admins.Auth.Tokens
  }
  def init(default), do: default

  def call(conn, _default) do
    with token when is_binary(token) <- get_session(conn, :apprent_manager_token),
         {:ok, %AppCountAuth.Users.AppRent{} = admin, new_token} <- @deps.tokens.verify(token) do
      # json(conn, new_token)
      conn
      |> put_session(:apprent_manager_token, new_token)
      |> put_resp_cookie("apprent_manager_token", new_token, http_only: false)
      |> assign(:admin, admin)
      |> assign(:user, admin)
      |> assign(:apprent_manager_token, new_token)
    else
      _ ->
        conn
        |> Phoenix.Controller.redirect(to: "/sessions")
        |> halt
    end
  end
end
