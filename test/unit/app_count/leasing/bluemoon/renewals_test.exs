defmodule AppCount.Leasing.BlueMoon.RenewalsTest do
  use AppCount.DataCase
  import AppCount.LeasingHelper
  alias AppCount.Leasing.BlueMoon.Renewals
  alias AppCount.Core.ClientSchema

  setup do
    today = AppCount.current_date()
    unit = insert(:unit, features: [])
    insert(:processor, property: unit.property, name: "BlueMoon", type: "lease")

    %{lease: lease} =
      insert_lease(%{
        start_date: today,
        end_date: Timex.shift(today, years: 1),
        charges: [
          Rent: 900,
          Pet: 25,
          Concession: -30
        ],
        unit: unit,
        tenants: [insert(:tenant), insert(:tenant)]
      })

    {:ok, unit: unit, lease: lease}
  end

  defmodule FakeBlueMoonGateWay do
    def get_lease_data(_, _) do
      :nothing
    end
  end

  test "bluemoon_renewal_params", %{lease: lease} do
    result =
      Renewals.renewal_params(ClientSchema.new("dasmen", lease.id), %{}, FakeBlueMoonGateWay)

    assert lease.end_date == result.start_date

    # TODO bring back this test, we need to make sure this is working but we need to port the packages stuff first
    #    assert result.rent == 1100
  end
end
