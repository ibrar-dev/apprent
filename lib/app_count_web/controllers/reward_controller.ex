defmodule AppCountWeb.RewardController do
  use AppCountWeb, :controller

  authorize(["Admin"])

  def index(conn, _params) do
    render(conn, "index.html", %{title: "Rewards"})
  end
end
