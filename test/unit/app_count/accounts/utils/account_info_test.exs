defmodule AppCount.Accounts.Utils.AccountInfoTest do
  use AppCount.DataCase
  import AppCount.LeasingHelper
  alias AppCount.Accounts
  alias AppCount.Maintenance.Order
  alias AppCount.Tenants.TenancyRepo
  alias AppCount.Core.ClientSchema
  @moduletag :account_info

  def money_as_decimal(number) do
    %Decimal{coef: number * 100, exp: -2, sign: 1}
  end

  setup do
    synced_property = insert(:property, setting: nil)
    insert(:setting, property_id: synced_property.id, sync_ledgers: true)
    internal_property = insert(:property, setting: nil)
    insert(:setting, property_id: internal_property.id, sync_ledgers: false)

    [internal_tenancy] =
      insert_lease(%{property: internal_property})
      |> Map.get(:tenancies)

    external_tenant = insert(:tenant, external_id: "111234")

    [external_tenancy] =
      insert_lease(%{property: synced_property, tenants: [external_tenant]})
      |> Map.get(:tenancies)

    {:ok,
     tenant_ids: %{int: internal_tenancy.tenant_id, ext: external_tenancy.tenant_id},
     tenancies: %{int: internal_tenancy, ext: external_tenancy}}
  end

  test "user_balance internal when no balance", %{tenant_ids: %{int: tenant_id}} do
    assert Accounts.user_balance(ClientSchema.new("dasmen", tenant_id)) == []
  end

  test "user_balance internal when positive balance", %{
    tenant_ids: %{int: tenant_id},
    tenancies: %{int: internal_tenancy}
  } do
    insert(:bill, customer_ledger: internal_tenancy.customer_ledger, amount: 100)
    insert(:payment, customer_ledger: internal_tenancy.customer_ledger, amount: 85)

    date =
      AppCount.current_date()
      |> Timex.format!("{M}/{YYYY}")

    expected = [%{date: date, balance: money_as_decimal(15)}]
    assert Accounts.user_balance(ClientSchema.new("dasmen", tenant_id)) == expected
  end

  test "user_balance external when no balance", %{tenant_ids: %{ext: tenant_id}} do
    assert Accounts.user_balance(ClientSchema.new("dasmen", tenant_id)) == []
  end

  test "user_balance external when positive balance", %{
    tenant_ids: %{ext: tenant_id},
    tenancies: %{ext: tenancy}
  } do
    TenancyRepo.update(tenancy, %{external_balance: 500})

    date =
      AppCount.current_date()
      |> Timex.format!("{M}/{YYYY}")

    expected = [%{date: date, balance: money_as_decimal(500)}]
    assert Accounts.user_balance(ClientSchema.new("dasmen", tenant_id)) == expected
  end

  test "user_balance_total internal", %{tenant_ids: %{int: tenant_id}} do
    assert Accounts.user_balance_total(tenant_id) == Decimal.new(0)
  end

  test "user_balance_total external", %{tenant_ids: %{ext: tenant_id}, tenancies: %{ext: tenancy}} do
    assert Accounts.user_balance_total(tenant_id) == Decimal.new(0)
    TenancyRepo.update(tenancy, %{external_balance: 500})
    assert Accounts.user_balance_total(tenant_id) == money_as_decimal(500)
  end

  test "get_assignment", context do
    tenant = context.tenancies.int.tenant
    order = insert(:order, tenant: tenant)
    assignment = insert(:assignment, order: order)
    params = Map.take(assignment, [:id, :rating, :tenant_comment, :order_id])

    expected =
      struct(AppCount.Maintenance.Assignment, params)
      |> Map.delete(:__meta__)

    tested =
      Accounts.get_assignment(tenant.id, assignment.id)
      |> Map.delete(:__meta__)

    assert tested == expected
  end

  test "create_order", context do
    category = insert(:category)
    tenant = context.tenancies.int.tenant
    params = %{"category_id" => category.id, "has_pet" => true}
    Accounts.create_order(tenant.id, params)
    assert Repo.get_by(Order, category_id: category.id, tenant_id: tenant.id, has_pet: true)
    reward_type = Repo.get_by(AppCount.Rewards.Type, name: "Work Order Created")

    assert Repo.get_by(AppCount.Rewards.Accomplishment,
             tenant_id: tenant.id,
             type_id: reward_type.id
           )
  end

  test "create_order error", context do
    tenant = context.tenancies.int.tenant
    params = %{"has_pet" => true}
    assert elem(Accounts.create_order(tenant.id, params), 0) == :error
  end

  test "create_order with note as string", context do
    category = insert(:category)
    tenant = context.tenancies.int.tenant

    b_64_pixel =
      "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII="

    params = %{"category_id" => category.id, "notes" => "Awesome note", "image" => b_64_pixel}
    AppCount.Support.HTTPClient.initialize(["{}"])
    Accounts.create_order(tenant.id, params)
    AppCount.Support.HTTPClient.stop()

    order =
      Repo.get_by(AppCount.Maintenance.Order, category_id: category.id, tenant_id: tenant.id)
      |> Repo.preload(:notes)

    assert hd(order.notes).text == "Awesome note"
  end

  test "create_order with note as Plug.Upload", context do
    category = insert(:category)
    tenant = context.tenancies.int.tenant
    upload = %Plug.Upload{path: Path.expand("../../../resources/sample.png", __DIR__)}
    params = %{"category_id" => category.id, "notes" => "Awesome note", "image" => upload}
    AppCount.Support.HTTPClient.initialize(["{}"])
    Accounts.create_order(tenant.id, params)
    AppCount.Support.HTTPClient.stop()

    order =
      Repo.get_by(AppCount.Maintenance.Order, category_id: category.id, tenant_id: tenant.id)
      |> Repo.preload(:notes)

    assert hd(order.notes).text == "Awesome note"
  end
end
