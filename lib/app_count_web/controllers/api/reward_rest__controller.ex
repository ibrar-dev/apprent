defmodule AppCountWeb.API.RewardRESTController do
  use AppCountWeb, :controller
  alias AppCount.Rewards

  def index(conn, _params) do
    json(conn, %{prizes: Rewards.list_rewards()})
  end

  def show(conn, %{"id" => tenant_id}) do
    json(conn, %{points: Rewards.tenant_points(tenant_id)})
  end

  def show(conn, %{"id" => tenant_id, "rewardHistory" => _}) do
    json(conn, %{points: Rewards.tenant_history(tenant_id)})
  end

  def create(conn, %{"reward" => params}) do
    Rewards.create_reward(params)
    json(conn, %{})
  end

  def update(conn, %{"id" => reward_id, "reward" => params}) do
    Rewards.update_reward(reward_id, params)
    json(conn, %{})
  end

  def delete(conn, %{"id" => reward_id}) do
    Rewards.delete_reward(reward_id)
    json(conn, %{})
  end
end
