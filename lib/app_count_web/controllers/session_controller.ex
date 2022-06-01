defmodule AppCountWeb.SessionController do
  use AppCountWeb, :controller

  plug(:put_layout, "sessions.html")

  def new(conn, _params) do
    render(conn, "new.html")
  end

  def create(conn, %{"create" => %{"email" => email, "password" => password}}) do
    case AppCount.Public.Auth.authenticate_user(email, password) do
      {:ok, user} ->
        conn
        |> assign(:admin, user)
        |> assign(:client_schema, user.client_schema)
        |> AppCountWeb.ConnectionAdapter.attrs("Logged in")
        |> AppCount.Admins.Utils.Actions.create_action()

        AppCountAuth.AuthServer.set_pass_on_new_login(user)

        put_session(conn, :admin_token, AppCountWeb.Token.token(user))
        |> redirect(to: Routes.dashboard_path(conn, :index))

      _ ->
        put_flash(conn, :error, "Invalid Login")
        |> redirect(to: Routes.session_path(conn, :new))
    end
  end

  def delete(conn, _params) do
    conn
    |> AppCountWeb.ConnectionAdapter.attrs("Logged out")
    |> AppCount.Admins.Utils.Actions.create_action()

    put_session(conn, :admin_token, nil)
    |> redirect(to: Routes.dashboard_path(conn, :index))
  end
end
