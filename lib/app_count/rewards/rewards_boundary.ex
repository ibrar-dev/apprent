defmodule AppCount.Rewards.RewardsBoundary do
  @moduledoc """
  Boundary
  """

  alias AppCount.Properties.PropertyRepo
  alias AppCount.Tenants.RewardTenantRepo
  alias AppCount.Core.DateTimeRange
  alias AppCount.Core.Bag
  alias AppCount.Core.Clock
  alias AppCount.Rewards.Purchase
  alias AppCount.Tenants.RewardTenant
  alias AppCount.Rewards.Accomplishment

  # Main Function
  def reward_analytics(property_ids, schema \\ "dasmen") when is_list(property_ids) do
    ytd_date_range = DateTimeRange.year_to_date()
    mtd_date_range = DateTimeRange.month_to_date()

    properties =
      property_ids
      |> load_properties_with_setting(schema)
      |> properties_with_rewards()

    reward_tenants_for_year = reward_tenants_for_year(properties, ytd_date_range)

    month_to_date_tenant_rewards = purchases_within_range(reward_tenants_for_year, mtd_date_range)

    most_frequent_accomplishment_type = %{
      ytd: reward_tenants_for_year |> most_frequent_accomplishment_type(),
      mtd: month_to_date_tenant_rewards |> most_frequent_accomplishment_type()
    }

    high_scoring_tenants = %{
      ytd: reward_tenants_for_year |> tenants_with_highest_points(),
      mtd: month_to_date_tenant_rewards |> tenants_with_highest_points()
    }

    most_purchased_reward_names = %{
      ytd:
        reward_tenants_for_year
        |> most_purchased_reward()
        |> Enum.map(& &1.name),
      mtd:
        month_to_date_tenant_rewards
        |> most_purchased_reward()
        |> Enum.map(& &1.name)
    }

    %{
      most_purchased_reward_names: most_purchased_reward_names,
      most_frequent_accomplishment_type: most_frequent_accomplishment_type,
      high_scoring_tenants: high_scoring_tenants
    }
  end

  def load_properties_with_setting(property_ids, schema) do
    property_ids
    |> Enum.map(fn property_id -> PropertyRepo.get(property_id, :setting, prefix: schema) end)
  end

  def properties_with_rewards(properties) do
    properties
    |> Enum.filter(fn property -> property_has_rewards?(property) end)
  end

  def property_has_rewards?(property) do
    property.setting.rewards
  end

  def reward_tenants_for_year(properties, ytd_date_range) do
    # Given properties, remove the purchases no withinthe datetime_range
    properties
    |> Enum.map(fn property -> tenant_ids(property, ytd_date_range) |> reward_tenants() end)
    |> purchases_within_range(ytd_date_range)
    |> List.flatten()
  end

  def tenant_ids(property, date_range) do
    date = DateTime.to_date(date_range.to)

    property.id
    |> AppCount.Tenants.TenantRepo.tenants_for_property(date)
    |> Enum.map(fn tenant -> tenant.id end)
  end

  def reward_tenants(tenant_ids) do
    tenant_ids
    |> Enum.map(fn tenant_id -> RewardTenantRepo.get_aggregate(tenant_id) end)
  end

  def purchases_within_range(reward_tenants, %DateTimeRange{} = date_range)
      when is_list(reward_tenants) do
    reward_tenants
    |> Enum.map(fn reward_tenant -> purchases_within_range(reward_tenant, date_range) end)
  end

  def purchases_within_range(reward_tenants, %DateTimeRange{} = date_range)
      when is_list(reward_tenants) do
    reward_tenants
    |> Enum.map(fn reward_tenant -> purchases_within_range(reward_tenant, date_range) end)
  end

  def purchases_within_range(reward_tenant, %DateTimeRange{} = date_range) do
    purchases_in_scope =
      reward_tenant.purchases
      |> Enum.filter(fn %{inserted_at: inserted_at} ->
        DateTimeRange.within?(date_range, Clock.to_utc(inserted_at))
      end)

    %{reward_tenant | purchases: purchases_in_scope}
  end

  def most_purchased_reward([]) do
    []
  end

  def most_purchased_reward(reward_tenants) when is_list(reward_tenants) do
    reward_tenants
    |> bag_of_rewards()
    |> Bag.max()
  end

  def bag_of_rewards(reward_tenants) do
    reward_tenants
    |> Enum.reduce(Bag.new(), &put_rewards(&1, &2))
  end

  defp put_rewards(%RewardTenant{purchases: purchases}, %Bag{} = bag) do
    purchases
    |> Enum.reduce(bag, fn %Purchase{} = purchase, %Bag{} = bag ->
      Bag.add(bag, purchase.reward)
    end)
  end

  def tenants_with_highest_points([]) do
    []
  end

  def tenants_with_highest_points(reward_tenants) do
    reward_tenants
    |> total_points_per_tenant()
    |> list_highest_points()
    |> extract_names()
  end

  defp extract_names(reward_tenants) do
    reward_tenants
    |> Enum.map(fn %RewardTenant{} = reward_tenant ->
      RewardTenant.name(reward_tenant)
    end)
  end

  defp total_points_per_tenant(reward_tenants) do
    reward_tenants
    |> Enum.map(fn %RewardTenant{} = reward_tenant ->
      points = total_points_accomplishments(reward_tenant.accomplishments)
      {reward_tenant, points}
    end)

    # [ {tenant, total_points}, {tenant, total_points}]
  end

  defp total_points_accomplishments(accomplishments) do
    accomplishments
    |> Enum.map(fn accomplishment -> accomplishment.type.points end)
    |> Enum.sum()
  end

  defp list_highest_points(tenant_total_points_tuple_list) do
    # tenant_total_points_tuple_list is like [ {tenant, total_points}, {tenant, total_points}]
    highest =
      tenant_total_points_tuple_list
      |> Enum.reduce(0, fn {_tenant, points}, acc ->
        if points > acc do
          points
        else
          acc
        end
      end)

    tenant_total_points_tuple_list
    |> Enum.filter(fn {_tenant, total_points} -> total_points == highest end)
    |> Enum.map(fn {tenant, _total_points} -> tenant end)
  end

  def most_frequent_accomplishment_type([]) do
    []
  end

  def most_frequent_accomplishment_type(reward_tenants) do
    reward_tenants
    |> accomplishments()
    |> bag_of_types()
    |> Bag.max()
    |> Enum.map(fn %{name: name} -> name end)
  end

  defp accomplishments(reward_tenants) do
    reward_tenants
    |> Enum.reduce([], fn %RewardTenant{} = reward_tenant, acc ->
      reward_tenant.accomplishments ++ acc
    end)
  end

  defp bag_of_types(accomplishments) do
    accomplishments
    |> Enum.reduce(%Bag{}, fn %Accomplishment{} = accomplishment, %Bag{} = bag ->
      Bag.add(bag, accomplishment.type)
    end)
  end
end
