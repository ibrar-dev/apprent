defmodule AppCountWeb.AuthenticateTechPlug do
  import Plug.Conn
  alias AppCount.Maintenance
  alias AppCount.Maintenance.Tech

  def init(default), do: default

  def call(conn, _) do
    with token when is_binary(token) <- get_cert(conn),
         %Tech{} = tech <- Maintenance.authenticate_tech(token) do
      conn
      |> put_session(:tech_token, token)
      |> assign(:tech, tech)
    else
      _ ->
        conn
        |> put_status(401)
        |> Phoenix.Controller.json(%{error: "Authentication Failed"})
        |> halt
    end
  end

  def get_cert(conn) do
    get_session(conn, :tech_token) || List.first(get_req_header(conn, "x-tech-token"))
  end
end
