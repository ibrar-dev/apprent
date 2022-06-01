defmodule AppCount.Leases.RenewalsTest do
  use AppCount.DataCase
  import AppCount.LeaseHelper
  alias AppCount.Leases
  @moduletag :renewals

  setup do
    today = AppCount.current_date()
    lease_end = Timex.shift(today, years: 1)

    period =
      insert(:renewal_period, start_date: today, end_date: Timex.shift(lease_end, months: 1))

    insert(
      :renewal_package,
      renewal_period: period,
      min: 10,
      max: 12,
      base: "Market Rent",
      dollar: false,
      amount: 10
    )

    package1 =
      insert(
        :renewal_package,
        min: 7,
        max: 7,
        base: "Current Rent",
        dollar: true,
        amount: 50,
        renewal_period: period
      )

    insert(:renewal_package,
      min: 8,
      max: 9,
      base: "Market Rent",
      dollar: true,
      amount: 50,
      renewal_period: period
    )

    insert(:renewal_package,
      min: 13,
      max: 14,
      base: "Current Rent",
      dollar: false,
      amount: 10,
      renewal_period: period
    )

    fp = insert(:floor_plan, property: period.property)
    insert(:floor_plan_feature, floor_plan: fp)
    insert(:floor_plan_feature, floor_plan: fp)
    insert(:floor_plan_feature, floor_plan: fp, feature: insert(:feature, price: 500))

    insert(
      :floor_plan_feature,
      floor_plan: fp,
      feature: insert(:feature, price: 500, stop_date: Timex.shift(today, days: -1))
    )

    unit = insert(:unit, property: period.property, features: [], floor_plan: fp)
    insert(:processor, property: period.property, name: "BlueMoon")
    # market rent should be 1000
    dfl = [
      insert(:default_lease_charge).id,
      insert(:default_lease_charge).id,
      insert(:default_lease_charge).id
    ]

    lease =
      insert_lease(%{
        start_date: today,
        end_date: Timex.shift(today, years: 1),
        charges: [
          Rent: 900,
          Pet: 25,
          Concession: -30
        ],
        deposit_amount: 500,
        unit: unit,
        pending_default_lease_charges: dfl,
        tenants: [insert(:tenant), insert(:tenant)]
      })

    {:ok, unit: unit, lease: lease, package1: package1}
  end

  test "new_lease_from_bluemoon_xml", %{lease: lease} do
    start = Timex.shift(lease.end_date, days: 5)
    renewal_end = Timex.shift(start, years: 1)

    params = %BlueMoon.Data.Lease{
      rent: 1000,
      unit: lease.unit.number,
      start_date: start,
      end_date: renewal_end
    }

    Leases.new_lease_from_bluemoon_xml(lease, params)

    leases =
      Repo.all(Leases.Lease)
      |> Repo.preload(:tenants)

    refreshed_lease = Enum.find(leases, &(&1.id == lease.id))
    renewal = Enum.find(leases, &(&1.id != lease.id))
    assert is_nil(refreshed_lease.pending_bluemoon_lease_id)
    assert is_nil(refreshed_lease.pending_bluemoon_signature_id)
    assert renewal.start_date == start
    assert renewal.end_date == renewal_end
    assert renewal.tenants == refreshed_lease.tenants
  end
end
