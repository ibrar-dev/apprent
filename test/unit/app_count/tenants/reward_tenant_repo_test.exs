defmodule AppCount.Tenants.RewardTenantRepoTest do
  use AppCount.DataCase
  alias AppCount.Tenants.RewardTenantRepo
  alias AppCount.Support.RewardBuilder

  test "get tenant from id" do
    tenant =
      RewardBuilder.new(:create)
      |> RewardBuilder.add_tenant()
      |> RewardBuilder.get_requirement(:tenant)

    assert RewardTenantRepo.get(tenant.id)
  end

  describe "tenant with a Accomplishment having a Reversal" do
    setup do
      builder =
        RewardBuilder.new(:create)
        |> RewardBuilder.add_tenant()
        |> RewardBuilder.add_type()
        |> RewardBuilder.add_accomplishment(reversal: %{something: "reversal description"})

      ~M[builder]
    end

    test "get_aggregate skips Accomplishment with Reversal", ~M[builder] do
      tenant = RewardBuilder.get_requirement(builder, :tenant)

      # When
      result = RewardTenantRepo.get_aggregate(tenant.id)

      assert result.id == tenant.id
      assert Ecto.assoc_loaded?(result.accomplishments)
      [] = result.accomplishments
    end
  end

  describe "tenant with a reward" do
    setup do
      builder =
        RewardBuilder.new(:create)
        |> RewardBuilder.add_tenant()
        |> RewardBuilder.add_type()
        |> RewardBuilder.add_accomplishment()

      ~M[builder]
    end

    test "get_aggregate with accomplishment", ~M[builder] do
      tenant = RewardBuilder.get_requirement(builder, :tenant)

      # When
      result = RewardTenantRepo.get_aggregate(tenant.id)

      assert result.id == tenant.id
      assert Ecto.assoc_loaded?(result.accomplishments)
      [accomplishment] = result.accomplishments
      assert Ecto.assoc_loaded?(accomplishment.type)
    end

    test "get_aggregate with reward", ~M[builder] do
      builder =
        builder
        |> RewardBuilder.add_property()
        |> RewardBuilder.add_reward()
        |> RewardBuilder.add_purchase()

      tenant = RewardBuilder.get_requirement(builder, :tenant)
      # When
      result = RewardTenantRepo.get_aggregate(tenant.id)

      assert result.id == tenant.id
      assert Ecto.assoc_loaded?(result.purchases)
      [purchase] = result.purchases
      assert Ecto.assoc_loaded?(purchase.reward)
    end
  end
end
