defmodule AppCount.Rewards.RewardRepo do
  alias AppCount.Repo
  alias AppCount.Rewards.Reward
  import Ecto.Query

  def list_rewards() do
    from(
      reward in Reward,
      select: map(reward, [:id, :name, :icon, :points, :price, :url, :promote])
    )
    |> Repo.all()
  end

  def list_rewards_filter(params) do
    from(
      reward in Reward,
      select: map(reward, [:id, :name, :icon, :points, :price, :url, :promote]),
      where: ilike(reward.name, ^"%#{params}%")
    )
    |> Repo.all()
  end

  def create_reward(params) do
    %Reward{}
    |> Reward.changeset(params)
    |> Repo.insert()
  end

  def update_reward(id, params) do
    Repo.get(Reward, id)
    |> Reward.changeset(params)
    |> Repo.update()
  end

  def delete_reward(id) do
    Repo.get(Reward, id)
    |> Repo.delete()
  end
end
