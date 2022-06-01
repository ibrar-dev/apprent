defmodule AppCount.Rewards.RewardsBoundaryTest do
  use AppCount.DataCase
  alias AppCount.Rewards.RewardsBoundary
  alias AppCount.Support.RewardBuilder
  alias AppCount.Properties.PropertyRepo
  alias AppCount.Core.DateTimeRange
  alias AppCount.Tenants.RewardTenantRepo
  alias AppCount.Tenants.RewardTenant
  alias AppCount.Core.ClientSchema

  setup do
    # NOTE: uses both
    # * PropertyBuilder to setup the leases
    # * RewardBuilder to create Rewards
    #
    prop_builder =
      PropBuilder.new(:create)
      |> PropBuilder.add_property()
      |> PropBuilder.add_unit()
      |> PropBuilder.add_tenant()
      |> PropBuilder.add_customer_ledger()
      |> PropBuilder.add_tenancy()

    property =
      prop_builder
      |> PropBuilder.get_requirement(:property)
      |> PropertyRepo.update_property_settings(
        ClientSchema.new(
          "dasmen",
          %{}
        )
      )

    tenant = PropBuilder.get_requirement(prop_builder, :tenant)
    reward_tenant = RewardTenantRepo.get_aggregate(tenant.id)

    reward_builder =
      RewardBuilder.new(:create)
      |> RewardBuilder.put_requirement(:property, property)
      |> RewardBuilder.put_requirement(:tenant, reward_tenant)

    date_range = DateTimeRange.year_to_date()
    ~M[property, tenant, reward_builder, prop_builder, date_range]
  end

  def add_tenant(prop_builder) do
    prop_builder =
      prop_builder
      |> PropBuilder.add_unit()
      |> PropBuilder.add_tenant()
      |> PropBuilder.add_customer_ledger()
      |> PropBuilder.add_tenancy()

    tenant = PropBuilder.get_requirement(prop_builder, :tenant)
    reward_tenant = RewardTenantRepo.get_aggregate(tenant.id)

    {prop_builder, reward_tenant}
  end

  describe "reward_analytics for" do
    setup(~M[reward_builder]) do
      purchased_last_month = Clock.now({-30, :days}) |> DateTime.to_naive()

      reward =
        reward_builder
        |> RewardBuilder.add_reward()
        |> RewardBuilder.add_purchase(inserted_at: purchased_last_month)
        |> RewardBuilder.get_requirement(:reward)

      ~M[reward]
    end

    def is_after_january? do
      DateTime.utc_now().month > 1
    end

    @tag :flaky
    test "reward_analytics for most_purchased_reward_names", ~M[reward, property] do
      # Fails in January of every year.
      if is_after_january?() do
        client = AppCount.Public.get_client_by_schema("dasmen")

        # When
        result = RewardsBoundary.reward_analytics([property.id], client.client_schema)

        assert result.most_purchased_reward_names == %{
                 mtd: [],
                 ytd: [reward.name]
               }
      end
    end

    @tag :flaky
    test "reward_analytics for high_scoring_tenant", ~M[property, tenant] do
      # Fails in January of every year.
      if is_after_january?() do
        client = AppCount.Public.get_client_by_schema("dasmen")

        # When
        result = RewardsBoundary.reward_analytics([property.id], client.client_schema)

        reward_tenant = RewardTenantRepo.get_aggregate(tenant.id)

        [mtd_tenant_name] = result.high_scoring_tenants.mtd
        [ytd_tenant_name] = result.high_scoring_tenants.ytd

        assert mtd_tenant_name == RewardTenant.name(reward_tenant)
        assert ytd_tenant_name == RewardTenant.name(reward_tenant)
      end
    end
  end

  describe "most_frequent_accomplishment_type/1" do
    test "zero" do
      reward_tenants = []
      result_types = RewardsBoundary.most_frequent_accomplishment_type(reward_tenants)
      assert result_types == []
    end

    test "one", ~M[tenant, reward_builder] do
      type =
        reward_builder
        |> RewardBuilder.add_type()
        |> RewardBuilder.add_accomplishment()
        |> RewardBuilder.get_requirement(:type)

      reward_tenant = RewardTenantRepo.get_aggregate(tenant.id)
      reward_tenants = [reward_tenant]
      # When
      [result_type_name] = RewardsBoundary.most_frequent_accomplishment_type(reward_tenants)

      assert result_type_name == type.name
    end

    test "many, two types are equally most frequent", ~M[tenant, reward_builder] do
      {reward_builder, type1} =
        reward_builder
        |> RewardBuilder.add_type()
        |> RewardBuilder.add_accomplishment()
        |> RewardBuilder.get(:type)

      {_reward_builder, type2} =
        reward_builder
        |> RewardBuilder.add_type()
        |> RewardBuilder.add_accomplishment()
        |> RewardBuilder.get(:type)

      reward_tenant = RewardTenantRepo.get_aggregate(tenant.id)
      reward_tenants = [reward_tenant]
      # When
      result_types = RewardsBoundary.most_frequent_accomplishment_type(reward_tenants)

      assert type1.name in result_types
      assert type2.name in result_types
    end

    test "many, two types, first is most frequent", ~M[tenant, reward_builder] do
      {reward_builder, type1} =
        reward_builder
        |> RewardBuilder.add_type()
        |> RewardBuilder.add_accomplishment()
        # added twice
        |> RewardBuilder.add_accomplishment()
        |> RewardBuilder.get(:type)

      {_reward_builder, type2} =
        reward_builder
        |> RewardBuilder.add_type()
        |> RewardBuilder.add_accomplishment()
        |> RewardBuilder.get(:type)

      reward_tenant = RewardTenantRepo.get_aggregate(tenant.id)
      reward_tenants = [reward_tenant]
      # When
      result_types = RewardsBoundary.most_frequent_accomplishment_type(reward_tenants)

      assert type1.name in result_types
      refute type2.name in result_types
    end

    test "many, two types, second is most frequent", ~M[tenant, reward_builder] do
      {reward_builder, type1} =
        reward_builder
        |> RewardBuilder.add_type()
        |> RewardBuilder.add_accomplishment()
        |> RewardBuilder.get(:type)

      {_reward_builder, type2} =
        reward_builder
        |> RewardBuilder.add_type()
        |> RewardBuilder.add_accomplishment()
        # added twice
        |> RewardBuilder.add_accomplishment()
        |> RewardBuilder.get(:type)

      reward_tenant = RewardTenantRepo.get_aggregate(tenant.id)
      reward_tenants = [reward_tenant]
      # When
      result_types = RewardsBoundary.most_frequent_accomplishment_type(reward_tenants)

      refute type1.name in result_types
      assert type2.name in result_types
    end
  end

  describe "reward_tenants_for_year" do
    test "in range", ~M[property, tenant, reward_builder] do
      _reward =
        reward_builder
        |> RewardBuilder.add_reward()
        |> RewardBuilder.add_purchase()
        |> RewardBuilder.get_requirement(:reward)

      reward_tenant = RewardTenantRepo.get_aggregate(tenant.id)
      ytd_date_range = DateTimeRange.today()

      # When
      [actual_reward_tenant] = RewardsBoundary.reward_tenants_for_year([property], ytd_date_range)
      assert actual_reward_tenant == reward_tenant
    end

    test "not in range", ~M[property,  reward_builder] do
      _reward =
        reward_builder
        |> RewardBuilder.add_reward()
        |> RewardBuilder.add_purchase()
        |> RewardBuilder.get_requirement(:reward)

      ytd_date_range = DateTimeRange.yesterday()

      # When
      [actual_reward_tenant] = RewardsBoundary.reward_tenants_for_year([property], ytd_date_range)

      # Then
      # actual_reward_tenant exists but has not purchases within the daterange
      assert actual_reward_tenant.purchases == []
    end
  end

  describe "tenants_with_highest_points/1" do
    test "zero" do
      reward_tenants = []
      tenants = RewardsBoundary.tenants_with_highest_points(reward_tenants)
      assert tenants == []
    end

    test "one", ~M[reward_builder] do
      tenant =
        reward_builder
        |> RewardBuilder.add_type()
        |> RewardBuilder.add_accomplishment()
        |> RewardBuilder.get_requirement(:tenant)

      reward_tenant = RewardTenantRepo.get_aggregate(tenant.id)
      reward_tenants = [reward_tenant]
      # When
      [actual_tenant_name] = RewardsBoundary.tenants_with_highest_points(reward_tenants)

      assert actual_tenant_name == RewardTenant.name(tenant)
    end

    test "many when both the same", ~M[reward_builder, prop_builder] do
      {reward_builder, tenant01} =
        reward_builder
        |> RewardBuilder.add_type()
        |> RewardBuilder.add_accomplishment()
        |> RewardBuilder.get(:tenant)

      {_prop_builder, second_tenant} = add_tenant(prop_builder)

      tenant02 =
        reward_builder
        |> RewardBuilder.put_requirement(:tenant, second_tenant)
        |> RewardBuilder.add_type()
        |> RewardBuilder.add_accomplishment()
        |> RewardBuilder.get_requirement(:tenant)

      reward_tenant01 = RewardTenantRepo.get_aggregate(tenant01.id)
      reward_tenant02 = RewardTenantRepo.get_aggregate(tenant02.id)

      reward_tenants = [reward_tenant01, reward_tenant02]
      # When
      actual_tenants = RewardsBoundary.tenants_with_highest_points(reward_tenants)

      # Then
      assert RewardTenant.name(tenant01) in actual_tenants
      assert RewardTenant.name(tenant02) in actual_tenants
    end

    test "many when first one has more points", ~M[reward_builder, prop_builder] do
      {reward_builder, tenant01} =
        reward_builder
        |> RewardBuilder.add_type(points: 50)
        |> RewardBuilder.add_accomplishment()
        |> RewardBuilder.get(:tenant)

      {_prop_builder, second_tenant} = add_tenant(prop_builder)

      tenant02 =
        reward_builder
        |> RewardBuilder.put_requirement(:tenant, second_tenant)
        |> RewardBuilder.add_type(points: 200)
        |> RewardBuilder.add_accomplishment()
        |> RewardBuilder.get_requirement(:tenant)

      reward_tenant01 = RewardTenantRepo.get_aggregate(tenant01.id)
      reward_tenant02 = RewardTenantRepo.get_aggregate(tenant02.id)

      reward_tenants = [reward_tenant01, reward_tenant02]
      # When
      actual_tenants = RewardsBoundary.tenants_with_highest_points(reward_tenants)

      # Then
      refute RewardTenant.name(tenant01) in actual_tenants
      assert RewardTenant.name(tenant02) in actual_tenants
    end

    test "many when second one has more points", ~M[reward_builder, prop_builder] do
      {reward_builder, tenant01} =
        reward_builder
        |> RewardBuilder.add_type(points: 250)
        |> RewardBuilder.add_accomplishment()
        |> RewardBuilder.get(:tenant)

      {_prop_builder, second_tenant} = add_tenant(prop_builder)

      tenant02 =
        reward_builder
        |> RewardBuilder.put_requirement(:tenant, second_tenant)
        |> RewardBuilder.add_type(points: 50)
        |> RewardBuilder.add_accomplishment()
        |> RewardBuilder.get_requirement(:tenant)

      reward_tenant01 = RewardTenantRepo.get_aggregate(tenant01.id)
      reward_tenant02 = RewardTenantRepo.get_aggregate(tenant02.id)

      reward_tenants = [reward_tenant01, reward_tenant02]
      # When
      actual_tenants = RewardsBoundary.tenants_with_highest_points(reward_tenants)

      # Then
      assert RewardTenant.name(tenant01) in actual_tenants
      refute RewardTenant.name(tenant02) in actual_tenants
    end
  end

  describe "most_purchased_reward/1" do
    test "zero" do
      reward_tenants = []
      # When
      result = RewardsBoundary.most_purchased_reward(reward_tenants)
      assert result == []
    end

    test "one", ~M[tenant, reward_builder] do
      reward =
        reward_builder
        |> RewardBuilder.add_reward()
        |> RewardBuilder.add_purchase()
        |> RewardBuilder.get_requirement(:reward)

      reward_tenant = RewardTenantRepo.get_aggregate(tenant.id)
      reward_tenants = [reward_tenant]

      # When
      [result_reward_name] =
        RewardsBoundary.most_purchased_reward(reward_tenants)
        |> Enum.map(& &1.name)

      assert result_reward_name == reward.name
    end

    test "many, two rewards both are most purchased", ~M[tenant, reward_builder] do
      {reward_builder, reward1} =
        reward_builder
        |> RewardBuilder.add_reward()
        |> RewardBuilder.add_purchase()
        |> RewardBuilder.get(:reward)

      {_reward_builder, reward2} =
        reward_builder
        |> RewardBuilder.add_reward()
        |> RewardBuilder.add_purchase()
        |> RewardBuilder.get(:reward)

      reward_tenant = RewardTenantRepo.get_aggregate(tenant.id)
      reward_tenants = [reward_tenant]

      # When
      result_reward_names =
        RewardsBoundary.most_purchased_reward(reward_tenants)
        |> Enum.map(& &1.name)

      assert reward1.name in result_reward_names
      assert reward2.name in result_reward_names
    end

    test "many, two rewards first is most purchased", ~M[tenant, reward_builder] do
      {reward_builder, reward1} =
        reward_builder
        |> RewardBuilder.add_reward()
        |> RewardBuilder.add_purchase()
        # added twice
        |> RewardBuilder.add_purchase()
        |> RewardBuilder.get(:reward)

      {_reward_builder, reward2} =
        reward_builder
        |> RewardBuilder.add_reward()
        |> RewardBuilder.add_purchase()
        |> RewardBuilder.get(:reward)

      reward_tenant = RewardTenantRepo.get_aggregate(tenant.id)
      reward_tenants = [reward_tenant]

      # When
      result_reward_names =
        RewardsBoundary.most_purchased_reward(reward_tenants)
        |> Enum.map(& &1.name)

      assert reward1.name in result_reward_names
      refute reward2.name in result_reward_names
    end

    test "many, two rewards second is most purchased", ~M[tenant, reward_builder] do
      {reward_builder, reward1} =
        reward_builder
        |> RewardBuilder.add_reward()
        |> RewardBuilder.add_purchase()
        |> RewardBuilder.get(:reward)

      {_reward_builder, reward2} =
        reward_builder
        |> RewardBuilder.add_reward()
        |> RewardBuilder.add_purchase()
        # added twice
        |> RewardBuilder.add_purchase()
        |> RewardBuilder.get(:reward)

      reward_tenant = RewardTenantRepo.get_aggregate(tenant.id)
      reward_tenants = [reward_tenant]

      # When
      result_reward_names =
        RewardsBoundary.most_purchased_reward(reward_tenants)
        |> Enum.map(& &1.name)

      refute reward1.name in result_reward_names
      assert reward2.name in result_reward_names
    end
  end

  describe "tenant_ids/1" do
    test "all", ~M[tenant, property, date_range] do
      [tenant_id] = RewardsBoundary.tenant_ids(property, date_range)
      assert tenant.id == tenant_id
    end

    test "two tenants", ~M[tenant, property, prop_builder, date_range] do
      {_prop_builder, second_tenant} = add_tenant(prop_builder)
      # When
      tenants = RewardsBoundary.tenant_ids(property, date_range)

      # Then
      assert tenant.id in tenants
      assert second_tenant.id in tenants
    end
  end

  describe "purchases_within_range/2" do
    setup(~M[ reward_builder ]) do
      reward_builder =
        reward_builder
        |> RewardBuilder.add_reward()

      # When
      reward_tenant = RewardBuilder.get_requirement(reward_builder, :tenant)
      date_range = DateTimeRange.today()

      ~M[reward_builder, reward_tenant, date_range]
    end

    test "purchase is  in range", ~M[reward_tenant, reward_builder, date_range] do
      RewardBuilder.add_purchase(reward_builder)

      reward_tenant = RewardTenantRepo.get_aggregate(reward_tenant.id)
      # When
      reward_tenant = RewardsBoundary.purchases_within_range(reward_tenant, date_range)
      # Then
      assert length(reward_tenant.purchases) == 1
    end

    test "purchase is out of range", ~M[reward_tenant, reward_builder, date_range] do
      times =
        AppTime.new()
        |> AppTime.plus_to_naive(:two_days_ago, days: -2)
        |> AppTime.times()

      RewardBuilder.add_purchase(reward_builder, inserted_at: times.two_days_ago)
      reward_tenant = RewardTenantRepo.get_aggregate(reward_tenant.id)

      # When
      reward_tenant = RewardsBoundary.purchases_within_range(reward_tenant, date_range)
      # Then
      assert Enum.empty?(reward_tenant.purchases)
    end
  end

  describe "reward_tenants aggregate" do
    setup(~M[ reward_builder ]) do
      reward_builder =
        reward_builder
        |> RewardBuilder.add_type()
        |> RewardBuilder.add_accomplishment()

      reward_tenant = RewardBuilder.get_requirement(reward_builder, :tenant)

      ~M[reward_builder, reward_tenant]
    end

    test "reward_tenants for tenant_ids", ~M[reward_builder] do
      tenant = RewardBuilder.get_requirement(reward_builder, :tenant)

      # When
      [reward_tenant] = RewardsBoundary.reward_tenants([tenant.id])

      assert reward_tenant
    end
  end

  test "empty reward_analytics", ~M[ property, tenant] do
    client = AppCount.Public.get_client_by_schema("dasmen")

    result = RewardsBoundary.reward_analytics([property.id], client.client_schema)
    # When
    reward_tenant = RewardTenantRepo.get_aggregate(tenant.id)

    assert result == %{
             most_purchased_reward_names: %{
               mtd: [],
               ytd: []
             },
             high_scoring_tenants: %{
               mtd: [RewardTenant.name(reward_tenant)],
               ytd: [RewardTenant.name(reward_tenant)]
             },
             most_frequent_accomplishment_type: %{
               mtd: [],
               ytd: []
             }
           }
  end

  describe "properties_with_rewards " do
    test "no propertes" do
      properties = []
      # When
      result = RewardsBoundary.properties_with_rewards(properties)
      assert result == properties
    end

    test "one property with rewards", ~M[  property] do
      property =
        property
        |> PropertyRepo.update_property_settings(
          ClientSchema.new(
            "dasmen",
            %{rewards: true}
          )
        )

      properties = [property]
      # When
      result = RewardsBoundary.properties_with_rewards(properties)
      assert result == properties
    end

    test "one property without rewards", ~M[  property] do
      property =
        property
        |> PropertyRepo.update_property_settings(
          ClientSchema.new(
            "dasmen",
            %{rewards: false}
          )
        )

      properties = [property]

      # When
      result = RewardsBoundary.properties_with_rewards(properties)
      assert result == []
    end
  end
end
