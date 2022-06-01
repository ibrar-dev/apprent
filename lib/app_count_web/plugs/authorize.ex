defmodule AppCountWeb.Authorize do
  import Phoenix.Controller, only: [json: 2, put_flash: 3, redirect: 2]
  import Plug.Conn, only: [put_status: 2, halt: 1]

  def do_authorize(%{assigns: %{admin: %{roles: %{map: %{"Super Admin" => []}}}}} = conn, _),
    do: conn

  def do_authorize(conn, roles) do
    conn.assigns.admin.roles
    |> MapSet.intersection(roles)
    |> MapSet.size()
    |> send_result(conn)
  end

  def send_result(0, conn), do: send_unauthorized(conn)
  def send_result(_, conn), do: conn

  def send_unauthorized(%{private: %{phoenix_flash: _}} = conn) do
    conn
    |> put_flash(:error, "Unauthorized Access")
    |> redirect(to: "/")
    |> halt
  end

  def send_unauthorized(conn) do
    conn
    |> put_status(:unauthorized)
    |> json(%{error: "unauthorized"})
    |> halt
  end

  defmacro authorize({:when, _, [roles, guards]}) do
    authorize(roles, %{}, guards)
  end

  defmacro authorize(roles) do
    authorize(roles, %{}, true)
  end

  defmacro authorize(roles, {:when, _, [special, guards]}) do
    authorize(roles, special, guards)
  end

  defmacro authorize(roles, special) do
    authorize(roles, special, true)
  end

  defp authorize(roles, special, guards) do
    roles =
      MapSet.new(roles)
      |> Macro.escape()

    special =
      special
      |> Enum.into(%{}, fn {k, v} -> {k, MapSet.new(v)} end)
      |> Macro.escape()

    quote do
      @plugs {:__authorize__, [], unquote(Macro.escape(guards))}

      defp __authorize__(%{private: %{phoenix_action: action}} = conn, _) do
        r = Map.get(unquote(special), action, unquote(roles))
        AppCountWeb.Authorize.do_authorize(conn, r)
      end
    end
  end
end
