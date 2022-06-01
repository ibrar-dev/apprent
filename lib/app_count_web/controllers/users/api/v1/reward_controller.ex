defmodule AppCountWeb.Users.API.V1.RewardController do
  use AppCountWeb.Users, :controller
  alias AppCount.Rewards

  def index(conn, _params) do
    {history, points} = Rewards.tenant_history(conn.assigns.user.id)
    rewards = Rewards.list_rewards()

    json(conn, %{prizes: rewards, points: points, history: history})
  end

  # Careful changing non colossal variable names.
  # AppRent Native was broken bc they were sending up "prize_id"
  def create(conn, %{"prize_id" => reward_id}) do
    case Rewards.purchase_reward(conn.assigns.user.id, reward_id) do
      {:ok, _} -> json(conn, %{})
      {:error, reason} -> json(conn, %{error: reason})
    end
  end

  def create(conn, %{"reward_id" => reward_id}) do
    case Rewards.purchase_reward(conn.assigns.user.id, reward_id) do
      {:ok, _} ->
        json(conn, %{})

      {:error, reason} ->
        conn
        |> put_status(422)
        |> json(%{error: reason})
    end
  end
end
