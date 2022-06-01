defmodule AppCountWeb.Users.RewardsChannel do
  alias AppCount.Rewards
  use AppCountWeb, :channel

  def join(_topic, _, socket) do
    {:ok, %{id: socket.assigns.user.id}, socket}
  end

  def join("rewards:" <> _, socket) do
    {:ok, socket}
  end

  def handle_in("SEARCH_REWARDS", params, socket) do
    broadcast!(socket, "SHOW_REWARDS", %{body: Rewards.list_rewards_filter(params)})

    {:ok, socket}
  end

  def handle_in("FETCH_REWARDS", _params, socket) do
    {:ok, socket}
  end
end
