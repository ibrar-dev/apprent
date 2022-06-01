defmodule AppCountWeb.Users.SessionController do
  use AppCountWeb.Users, :controller
  alias AppCount.Accounts

  def index(conn, _params) do
    render(conn, "index.html", layout: {AppCountWeb.Users.LayoutView, "login.html"})
  end

  def create(conn, %{"login" => %{"email" => email, "password" => password}}) do
    case AppCount.Public.Auth.authenticate_user(email, password) do
      # If a tenant from an inactive property tres to login
      {:ok, %{active: false}} ->
        put_flash(conn, :error, "No longer under AppRent management")
        |> redirect(to: Routes.user_session_path(conn, :index))

      {:ok, user} ->
        Accounts.create_login(%{account_id: user.account_id, type: "web"})

        token = AppCountWeb.Token.token(user)

        put_session(conn, :user_token, token)
        |> redirect(to: Routes.user_dashboard_path(conn, :index))

      _ ->
        put_flash(conn, :error, "Invalid Login")
        |> redirect(to: Routes.user_session_path(conn, :index))
    end
  end

  def delete(conn, _params) do
    put_session(conn, :user_token, nil)
    |> redirect(to: Routes.user_session_path(conn, :index))
  end
end
