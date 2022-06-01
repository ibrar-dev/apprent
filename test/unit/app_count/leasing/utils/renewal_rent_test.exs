defmodule AppCount.Leasing.RenewalRentTest do
  use AppCount.DataCase
  import AppCount.LeasingHelper
  alias AppCount.Leasing.Utils.RenewalRent
  alias AppCount.Core.ClientSchema
  @moduletag :renewal_rent

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

    insert(
      :renewal_package,
      min: 8,
      max: 9,
      base: "Market Rent",
      dollar: true,
      amount: 50,
      renewal_period: period
    )

    insert(
      :renewal_package,
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

    %{lease: lease} =
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

  test "calculates renewal rent", %{lease: lease, package1: package1} do
    today = AppCount.current_date()

    assert RenewalRent.rent_for(
             ClientSchema.new("dasmen", lease),
             Timex.shift(today, months: 18),
             Timex.shift(today, months: 28)
           ) == 0

    assert RenewalRent.rent_for(
             ClientSchema.new("dasmen", lease),
             today,
             Timex.shift(today, months: 6)
           ) == 0

    assert RenewalRent.rent_for(
             ClientSchema.new("dasmen", lease),
             today,
             Timex.shift(today, months: 12)
           ) == 1100

    insert(:custom_package, amount: 800, lease: lease, renewal_package: package1)

    assert RenewalRent.rent_for(
             ClientSchema.new("dasmen", lease),
             Timex.shift(today, months: 18),
             Timex.shift(today, months: 28)
           ) == 0

    assert RenewalRent.rent_for(
             ClientSchema.new("dasmen", lease),
             today,
             Timex.shift(today, months: 6)
           ) == 0

    assert RenewalRent.rent_for(
             ClientSchema.new("dasmen", lease),
             today,
             Timex.shift(today, months: 11)
           ) == 1100

    today_string = Timex.format!(today, "{YYYY}-{0M}-{0D}")

    seven_months =
      Timex.shift(today, months: 7)
      |> Timex.format!("{YYYY}-{0M}-{0D}")

    assert RenewalRent.rent_for(
             ClientSchema.new("dasmen", lease),
             today,
             Timex.shift(today, months: 7)
           ) == 800

    assert RenewalRent.rent_for(ClientSchema.new("dasmen", lease), today_string, seven_months) ==
             800
  end
end
