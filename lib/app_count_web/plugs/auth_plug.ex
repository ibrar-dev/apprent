defmodule AppCountWeb.AuthPlug do
  import Plug.Conn
  import Phoenix.Controller, only: [get_format: 1, redirect: 2, json: 2]
  @salt "d552nb!x$mdFg20LM"
  @max_token_age 259_200

  def init(default), do: default

  def call(conn, _default) do
    with token when is_binary(token) <- get_token(conn),
         {:ok, user, _new_token} <- token_to_user_struct(conn, token) do
      assign(conn, :user, user)
    else
      _ ->
        conn
        |> handle_error()
        |> halt
    end
  end

  def handle_error(conn) do
    case get_format(conn) do
      "html" ->
        conn
        |> redirect(to: AppCountWeb.Router.Helpers.session_path(conn, :new))

      "json" ->
        conn
        |> put_status(401)
        |> json(%{error: "Authentication Failed"})
    end
  end

  def get_token(conn) do
    get_session(conn, :admin_token) || List.first(get_req_header(conn, "x-admin-token"))
  end

  defp token_to_user_struct(conn, token) do
    conn
    |> Phoenix.Token.verify(@salt, token, max_age: @max_token_age)
    |> handle_ok_error
  end

  defp handle_ok_error({:ok, binary}), do: :erlang.binary_to_term(binary)
  defp handle_ok_error({:error, _} = e), do: e
end
