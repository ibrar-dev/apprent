defmodule AppCount.Leasing.RenewalPackagesTest do
  use AppCount.DataCase
  import AppCount.LeasingHelper
  alias AppCount.Leasing.Utils.RenewalPackages
  alias AppCount.Leasing.RenewalPackage
  alias AppCount.Core.ClientSchema

  @moduletag :renewal_packages

  setup do
    today = AppCount.current_date()
    p = insert(:renewal_package, min: 10, max: 12, base: "Market Rent", dollar: false, amount: 10)
    period = p.renewal_period

    insert(:renewal_package,
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
    # market rent should be 1000
    %{lease: lease} =
      insert_lease(%{
        start_date: today,
        end_date: Timex.shift(today, years: 1),
        charges: [
          rent: 900,
          Pet: 25,
          Concession: -30
        ],
        unit: unit
      })

    {:ok, lease: lease}
  end

  test "calculates package price", %{lease: lease} do
    today = AppCount.current_date()
    schema = ClientSchema.new("dasmen", lease)

    assert RenewalPackages.package_price(schema, 11, Timex.shift(today, months: 6)) == 0
    assert RenewalPackages.package_price(schema, 11, today) == 1100
    assert RenewalPackages.package_price(schema, 7, today) == 950
    assert RenewalPackages.package_price(schema, 8, today) == 1050
    assert RenewalPackages.package_price(schema, 13, today) == 990
  end

  @tag :note
  test "add_note" do
    package = insert(:renewal_package)

    RenewalPackages.add_note(ClientSchema.new("dasmen", package.id), "Cool note", insert(:admin))

    [note] = Repo.get(RenewalPackage, package.id, prefix: "dasmen").notes
    assert note["text"] == "Cool note"
  end
end
