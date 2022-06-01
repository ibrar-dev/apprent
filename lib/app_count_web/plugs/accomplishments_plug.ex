defmodule AppCountWeb.AccomplishmentsPlug do
  import Plug.Conn

  @deps %{rewards: AppCount.Rewards}

  def init(default), do: default

  def call(conn, _default) do
    start =
      AppCount.current_time()
      |> Timex.beginning_of_month()

    conn
    |> assign(
      :accomplishments,
      @deps.rewards.list_accomplishments(conn.assigns.user.id, start)
    )
  end
end
