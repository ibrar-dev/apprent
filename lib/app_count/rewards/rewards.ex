defmodule AppCount.Rewards do
  alias AppCount.Rewards.AccomplishmentRepo
  alias AppCount.Rewards.RewardRepo
  alias AppCount.Rewards.Utils.Types
  alias AppCount.Rewards.Utils.Purchases

  def list_accomplishments(params, start \\ nil),
    do: AccomplishmentRepo.list_accomplishments(params, start)

  def tenant_points(tenant_id), do: AccomplishmentRepo.tenant_points(tenant_id)
  def create_accomplishment(params), do: AccomplishmentRepo.create_accomplishment(params)
  def update_accomplishment(id, params), do: AccomplishmentRepo.update_accomplishment(id, params)
  def delete_accomplishment(id), do: AccomplishmentRepo.delete_accomplishment(id)
  def tenant_history(tenant_id), do: AccomplishmentRepo.tenant_history(tenant_id)

  def list_rewards(), do: RewardRepo.list_rewards()
  def list_rewards_filter(params), do: RewardRepo.list_rewards_filter(params)
  def create_reward(params), do: RewardRepo.create_reward(params)
  def update_reward(id, params), do: RewardRepo.update_reward(id, params)
  def delete_reward(id), do: RewardRepo.delete_reward(id)

  def list_purchases(tenant_id), do: Purchases.list_purchases(tenant_id)
  def purchase_reward(tenant_id, reward_id), do: Purchases.purchase_reward(tenant_id, reward_id)

  def purchase_rewards(tenant_id, reward_ids),
    do: Purchases.purchase_rewards(tenant_id, reward_ids)

  def create_purchase(params), do: Purchases.create_purchase(params)
  def update_purchase(id, params), do: Purchases.update_purchase(id, params)
  def delete_purchase(id), do: Purchases.delete_purchase(id)

  def list_types(), do: Types.list_types()
  def create_type(params), do: Types.create_type(params)
  def update_type(id, params), do: Types.update_type(id, params)
  def delete_type(id), do: Types.delete_type(id)
end
