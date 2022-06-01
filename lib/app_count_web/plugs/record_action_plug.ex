defmodule AppCountWeb.RecordActionPlug do
  def init(default), do: default

  def call(%{method: "GET"} = conn, _default), do: conn
  def call(%{method: "DELETE", path_info: ["sessions"]} = conn, _default), do: conn

  def call(conn, _default) do
    AppCount.Core.Tasker.start(fn ->
      conn
      |> AppCountWeb.ConnectionAdapter.attrs()
      |> AppCount.Admins.Utils.Actions.create_action()
    end)

    conn
  end
end
