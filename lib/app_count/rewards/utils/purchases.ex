defmodule AppCount.Rewards.Utils.Purchases do
  alias AppCount.Repo
  alias AppCount.Rewards.Purchase
  alias AppCount.Rewards.Reward
  alias AppCount.Tenants.Utils.Tenants
  import Ecto.Query

  def list_purchases(%{} = admin) do
    from(
      p in Purchase,
      join: t in assoc(p, :tenant),
      join: pr in assoc(p, :reward),
      join: prop in assoc(p, :property),
      where: p.property_id in ^admin.property_ids,
      select: map(p, [:id, :status, :points, :property_id, :inserted_at]),
      select_merge: %{
        tenant: map(t, [:id, :first_name, :last_name]),
        reward: map(pr, [:id, :name, :icon, :url]),
        property: prop.name
      }
    )
    |> Repo.all(prefix: admin.client_schema)
  end

  def list_purchases(tenant_id) do
    from(
      p in Purchase,
      join: pr in assoc(p, :reward),
      select: map(p, [:id, :status, :points, :inserted_at]),
      select_merge: %{
        reward: map(pr, [:id, :name, :icon, :points, :url])
      },
      where: p.tenant_id == ^tenant_id
    )
    |> Repo.all()
  end

  def create_purchase(params) do
    %Purchase{}
    |> Purchase.changeset(params)
    |> Repo.insert()
    |> case do
      {:ok, p} ->
        purchase = Repo.preload(p, [:reward, :tenant])
        property = Tenants.property_for(purchase.tenant_id)

        if purchase.tenant.email do
          AppCountCom.Rewards.purchase_tenant(purchase, property)
        end

        {:ok, p}

      e ->
        e
    end
  end

  def update_purchase(id, params) do
    Repo.get(Purchase, id)
    |> Purchase.changeset(params)
    |> Repo.update()
  end

  def delete_purchase(id) do
    Repo.get(Purchase, id)
    |> Repo.delete()
  end

  def purchase_reward(tenant_id, reward_id) do
    reward = Repo.get(Reward, reward_id)

    cond do
      AppCount.Rewards.tenant_points(tenant_id) >= reward.points ->
        %{id: property_id} = Tenants.property_for(tenant_id)

        %{
          points: reward.points,
          tenant_id: tenant_id,
          reward_id: reward_id,
          property_id: property_id,
          status: "pending"
        }
        |> create_purchase()

      true ->
        {:error, "Not enough points"}
    end
  end

  def purchase_rewards(tenant_id, reward_ids) do
    Enum.each(reward_ids, fn reward_id ->
      reward = Repo.get(Reward, reward_id)
      %{id: property_id} = Tenants.property_for(tenant_id)

      %{
        points: reward.points,
        tenant_id: tenant_id,
        reward_id: reward_id,
        property_id: property_id,
        status: "pending"
      }
      |> create_purchase()
    end)
  end
end
