defmodule AppCountWeb.PasswordController do
  use AppCountWeb, :controller
  alias AppCount.Admins

  plug(:put_layout, "sessions.html")

  def index(conn, %{"token" => token}) do
    render(conn, "edit.html", %{token: token})
  end

  def index(conn, _) do
    render(conn, "index.html")
  end

  def create(conn, %{"email" => email}) do
    case Admins.reset_password_request(email) do
      {:error, e} ->
        conn
        |> put_flash(:error, e)
        |> redirect(to: Routes.password_path(conn, :index))

      _ ->
        conn
        |> put_flash(:success, "Reset instructions sent, please check your emails")
        |> redirect(to: Routes.session_path(conn, :new))
    end
  end

  def update(conn, %{"token" => token, "password" => password, "confirmation" => confirmation}) do
    case Admins.reset_password(token, password, confirmation) do
      {:error, e} ->
        conn
        |> put_flash(:error, e)
        |> render("edit.html", %{token: token})

      _ ->
        conn
        |> put_flash(:success, "Password successfully reset, please login")
        |> redirect(to: Routes.session_path(conn, :new))
    end
  end
end
