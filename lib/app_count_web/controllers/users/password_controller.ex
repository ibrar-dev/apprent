defmodule AppCountWeb.Users.PasswordController do
  use AppCountWeb.Users, :controller
  alias AppCount.Accounts

  def index(conn, %{"token" => token}) do
    render(conn, "reset.html", layout: {AppCountWeb.Users.LayoutView, "login.html"}, token: token)
  end

  def index(conn, _params) do
    render(conn, "index.html", layout: {AppCountWeb.Users.LayoutView, "login.html"})
  end

  def create(conn, %{"reset" => %{"username" => username}}) do
    case Accounts.reset_password_request(username) do
      {:ok, email} ->
        conn
        |> put_flash(:success, "Reset password email sent to #{email}")
        |> redirect(to: Routes.user_session_path(conn, :index))

      {:error, :no_username} ->
        conn
        |> put_flash(:error, "Username not found.")
        |> redirect(to: Routes.user_password_path(conn, :index))

      {:error, :no_email} ->
        conn
        |> put_flash(:error, "No email associated with this account, please contact support.")
        |> redirect(to: Routes.user_password_path(conn, :index))

      {:error, :no_property_assoc} ->
        conn
        |> put_flash(
          :error,
          "No property associated with this account, please contact support."
        )
        |> redirect(to: Routes.user_password_path(conn, :index))
    end
  end

  def update(conn, %{
        "reset" => %{"password" => password, "token" => token, "confirmation" => confirmation}
      }) do
    case Accounts.reset_password(token, password, confirmation) do
      {:ok, _} ->
        conn
        |> put_flash(:success, "Password reset successfully")
        |> redirect(to: Routes.user_session_path(conn, :index))

      {:error, e} ->
        conn
        |> put_flash(:error, e)
        |> redirect(to: Routes.user_password_path(conn, :index, token: token))
    end
  end
end
