defmodule AppCountWeb.Management.SessionController do
  use AppCountWeb, :controller

  plug(:put_layout, "sessions.html")

  def new(conn, _params) do
    render(conn, "new.html")
  end

  def create(conn, %{"create" => %{"email" => email, "password" => password}}) do
    case AppCount.Public.Auth.authenticate_user(email, password) do
      {:ok, %AppCountAuth.Users.AppRent{} = user} ->
        conn
        |> assign(:admin, user)
        |> Map.put(:admin_id, user.id)

        put_session(
          conn,
          :apprent_manager_token,
          AppCountWeb.Token.token(user)
        )
        |> redirect(to: Routes.client_path(conn, :index))

      _ ->
        put_flash(conn, :error, "Invalid Login")
        |> redirect(to: Routes.session_path(conn, :new))
    end
  end

  def delete(conn, _params) do
    put_session(conn, :apprent_manager_token, nil)
    |> redirect(to: Routes.dashboard_path(conn, :index))
  end
end
