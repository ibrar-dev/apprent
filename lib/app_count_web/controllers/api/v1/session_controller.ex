defmodule AppCountWeb.API.V1.SessionController do
  use AppCountWeb, :controller

  def create(conn, params) do
    with %{"email" => email, "password" => password} <- params,
         {:ok, user} <- AppCount.Public.Auth.authenticate_user(email, password) do
      token = AppCountWeb.Token.token(user)
      AppCountAuth.AuthServer.set_pass_on_new_login(user)
      json(conn, %{token: token, roles: user.roles})
    else
      _error ->
        json(conn, %{error: "Invalid Authentication"})
    end
  end
end
