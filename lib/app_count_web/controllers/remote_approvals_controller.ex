defmodule AppCountWeb.RemoteApprovalsController do
  use AppCountWeb, :controller
  alias AppCount.Approvals

  plug(:put_layout, "approvals.html")

  def index(conn, %{"token" => token, "status" => params}) do
    # TODO:SCHEMA fix this schema issue when we find out what this does
    case Approvals.create_log_from_token(token, params, "dasmen") do
      {:error, e} ->
        conn
        |> put_flash(:error, e)
        |> render("edit.html", %{token: token})

      _ ->
        conn
        |> put_flash(:success, "#{params} successfully logged")
        |> render("edit.html", %{token: token})
    end
  end

  def index(conn, %{"token" => token}) do
    render(conn, "edit.html", %{token: token})
  end
end
