defmodule AppCount.Tenants.TenancyRepoTest do
  use AppCount.DataCase
  alias AppCount.Tenants.TenancyRepo
  @moduletag :tenancy_repo

  test "current tenancies by tenant" do
    tenant = insert(:tenant)
    today = AppCount.current_date()
    current = insert(:tenancy, tenant: tenant)
    # future tenancy
    insert(:tenancy, start_date: Timex.shift(today, days: 32), tenant: tenant)

    past =
      insert(:tenancy,
        start_date: Timex.shift(today, years: -1),
        actual_move_out: today,
        tenant: tenant
      )

    [result] = TenancyRepo.current_tenancies_for_tenant(tenant.id)
    assert result.id == current.id
    [result] = TenancyRepo.current_tenancies_for_tenant(tenant.id, Timex.shift(today, days: -1))
    assert result.id == past.id
  end

  test "current tenancy future tenant" do
    tenant = insert(:tenant)

    date =
      AppCount.current_date()
      |> Timex.shift(days: 20)

    future = insert(:tenancy, tenant: tenant)

    past =
      insert(:tenancy,
        start_date: Timex.shift(date, years: -1),
        actual_move_out: date,
        tenant: tenant
      )

    [result] = TenancyRepo.current_tenancies_for_tenant(tenant.id)
    assert result.id == future.id
    [result] = TenancyRepo.current_tenancies_for_tenant(tenant.id, Timex.shift(date, days: -30))
    assert result.id == past.id
  end

  test "current tenancies by unit" do
    unit = insert(:unit)
    today = AppCount.current_date()
    current = insert(:tenancy, unit: unit)
    # future tenancy
    insert(:tenancy, start_date: Timex.shift(today, days: 30), unit: unit)

    past =
      insert(:tenancy,
        start_date: Timex.shift(today, years: -1),
        actual_move_out: today,
        unit: unit
      )

    [result] = TenancyRepo.current_tenancies_for_unit(unit.id)
    assert result.id == current.id
    [result] = TenancyRepo.current_tenancies_for_unit(unit.id, Timex.shift(today, days: -1))
    assert result.id == past.id
  end
end
