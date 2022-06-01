defmodule AppCount.Leases.RenewalLettersTest do
  use AppCount.DataCase
  import AppCount.LeasingHelper
  alias AppCount.Leasing.Utils.RenewalLetters
  alias AppCount.Properties
  alias AppCount.Core.ClientSchema

  @moduletag :renewal_letters

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
    %{lease: lease, tenancies: [tenancy]} =
      insert_lease(%{
        start_date: Timex.shift(today, years: -1),
        end_date: today,
        charges: [
          Rent: 900,
          Pet: 25,
          Concession: -30
        ],
        unit: unit
      })

    {:ok, lease: lease, period: period, tenant_id: tenancy.tenant_id}
  end

  @tag :slow
  test "generates renewal letters", %{period: period, tenant_id: tenant_id} do
    RenewalLetters.generate(ClientSchema.new("dasmen", period.id))

    assert Repo.get_by(Properties.Document, [tenant_id: tenant_id, type: "Renewal Offer"],
             prefix: "dasmen"
           )
  end
end
