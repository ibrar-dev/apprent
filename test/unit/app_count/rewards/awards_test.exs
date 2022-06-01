defmodule AppCount.Rewards.AccomplishmentsTest do
  use AppCount.DataCase
  alias AppCount.Rewards
  alias AppCount.Rewards.Type
  alias AppCount.Core.ClientSchema
  @moduletag :accomplishments

  setup do
    tenant = insert(:tenancy).tenant

    type = Repo.get_by(Type, name: "Payment")
    Rewards.update_type(type.id, %{points: 500, monthly_max: 2, active: true})
    {:ok, tenant: tenant, type: type}
  end

  test "creates accomplishment", %{tenant: tenant} do
    {:ok, accomplishment} =
      Rewards.create_accomplishment(
        ClientSchema.new("dasmen", %{tenant_id: tenant.id, type: "Payment"})
      )

    assert accomplishment.tenant_id == tenant.id
    assert accomplishment.amount == 500
  end

  test "honors monthly max", %{tenant: tenant} do
    {:ok, _} =
      Rewards.create_accomplishment(
        ClientSchema.new("dasmen", %{tenant_id: tenant.id, type: "Payment"})
      )

    {:ok, _} =
      Rewards.create_accomplishment(
        ClientSchema.new("dasmen", %{tenant_id: tenant.id, type: "Payment"})
      )

    {:error, e} =
      Rewards.create_accomplishment(
        ClientSchema.new("dasmen", %{tenant_id: tenant.id, type: "Payment"})
      )

    assert e == "Tenant has reached max rewards for this month"
  end

  test "returns error for non-existent category", %{tenant: tenant} do
    {:error, e} =
      Rewards.create_accomplishment(
        ClientSchema.new("dasmen", %{tenant_id: tenant.id, type: "Jumping Jacks"})
      )

    assert e == "No such category."
  end

  test "returns error for inactive category", %{tenant: tenant, type: type} do
    Rewards.update_type(type.id, %{active: false})

    {:error, e} =
      Rewards.create_accomplishment(
        ClientSchema.new("dasmen", %{tenant_id: tenant.id, type: "Payment"})
      )

    assert e == "Category is not active or rewards deactivated for this property."
  end
end
