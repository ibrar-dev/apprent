defmodule AppCountWeb.API.SessionController do
  use AppCountWeb, :controller

  def create(conn, %{"email" => email, "password" => password}) do
    with {:ok, user} <- AppCount.Public.Auth.authenticate_user(email, password) do
      token = AppCountWeb.Token.token(user)

      json(conn, %{token: token, roles: user.roles})
      # json(conn, %{token: token, roles: []})
    else
      {:error, _admin} ->
        json(conn, %{error: "Invalid Authentication"})
    end
  end

  def delete(conn, _params) do
    put_session(conn, :admin_token, nil)
    json(conn, %{})
  end
end
