defmodule AppCountWeb.AuthorizationPlug do
  import Plug.Conn

  @authorizer_provider Application.compile_env(
                         :app_count,
                         :authorization_provider,
                         AppCountAuth.Provider
                       )

  def init(default), do: default

  def call(conn, _default) do
    controller = conn.private.phoenix_controller
    action = conn.private.phoenix_action
    params = conn.params

    mod = @authorizer_provider.authorizer_for(controller, action)

    cond do
      mod == false ->
        conn

      is_atom(mod) and apply(mod, action, [conn.assigns[:user], params]) ->
        conn

      true ->
        conn
        |> put_status(403)
        |> Phoenix.Controller.json(%{error: "Authorization Failed"})
        |> halt
    end
  end
end
