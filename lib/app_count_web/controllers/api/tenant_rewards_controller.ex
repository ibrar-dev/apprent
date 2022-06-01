defmodule AppCountWeb.API.TenantRewardsController do
  use AppCountWeb, :controller
  alias AppCount.Rewards

  def index(conn, %{"awardType" => _}) do
    safe_json(conn, Rewards.list_types())
  end

  def index(conn, %{"rewards" => _}) do
    json(conn, Rewards.list_rewards())
  end

  def show(conn, %{"id" => tenant_id, "rewardHistory" => _}) do
    safe_json(conn, Rewards.tenant_history(tenant_id))
  end

  def show(conn, %{"id" => tenant_id, "awardHistory" => _}) do
    json(conn, Rewards.list_accomplishments(tenant_id))
  end

  def show(conn, %{"id" => tenant_id, "purchaseHistory" => _}) do
    json(conn, Rewards.list_purchases(tenant_id))
  end

  def show(conn, %{"id" => tenant_id}) do
    json(conn, Rewards.tenant_points(tenant_id))
  end

  def create(conn, %{"newAward" => newAccomplishment}) do
    map = Map.put(newAccomplishment, "created_by", conn.assigns.admin.name)
    Rewards.create_accomplishment(map)
    json(conn, %{})
  end

  def create(conn, %{"newPurchase" => newPurchase}) do
    Rewards.purchase_reward(newPurchase["tenant_id"], newPurchase["reward_id"])
    json(conn, %{})
  end

  def delete(conn, %{"id" => accomplishment_id}) do
    Rewards.delete_accomplishment(accomplishment_id)
    json(conn, %{})
  end
end
