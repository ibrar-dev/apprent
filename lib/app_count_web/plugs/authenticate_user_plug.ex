defmodule AppCountWeb.AuthenticateUserPlug do
  import Plug.Conn
  alias AppCountWeb.Router.Helpers, as: Routes
  alias Phoenix.Controller

  @deps %{
    accounts: Module.concat(["AppCount.Accounts"])
  }

  def init(default), do: default

  def call(conn, _default) do
    with token when is_binary(token) <- get_token(conn),
         {:ok, %{} = user, new_token} <- @deps.accounts.verify_token(token) do
      conn
      |> put_session(:user_token, new_token)
      |> assign(:user, user)
      |> assign(:user_token, new_token)
      |> assign(:client_schema, user.client_schema)
    else
      _ ->
        conn
        |> Controller.redirect(to: Routes.user_session_path(conn, :index))
        |> halt
    end
  end

  def get_token(conn) do
    get_session(conn, :user_token) || List.first(get_req_header(conn, "x-user-token"))
  end
end
