defmodule AppCount.Unit.MarketRentTest do
  use AppCount.DataCase
  alias AppCount.Units
  alias AppCount.Properties.PropertyRepo
  alias AppCount.Core.ClientSchema

  @moduletag :market_rent

  setup do
    features = [
      insert(:feature, price: 450),
      insert(:feature, price: 350),
      insert(:feature, price: 200)
    ]

    floor_plan = insert(:floor_plan, features: features)

    unit =
      insert(
        :unit,
        area: 800,
        floor_plan: floor_plan,
        features: [insert(:feature, price: 100), insert(:feature, price: 100)]
      )

    _property =
      PropertyRepo.get(unit.property_id)
      |> AppCount.Properties.PropertyRepo.update_property_settings(
        ClientSchema.new(
          "dasmen",
          %{area_rate: 0.50}
        )
      )

    {:ok, [unit: unit]}
  end

  test "gets market rent", %{unit: unit} do
    assert Units.market_rent(ClientSchema.new("dasmen", unit.id)) == 1600
  end
end
