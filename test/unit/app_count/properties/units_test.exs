defmodule AppCount.Properties.UnitsTest do
  use AppCount.DataCase
  alias AppCount.Properties
  alias AppCount.Core.ClientSchema

  setup do
    Repo.delete_all(Properties.Feature)
    unit = insert(:unit, features: [])

    features = [
      insert(:feature, name: "2 Bedroom", price: 180, property: unit.property),
      insert(:feature, name: "2 Bathroom", price: 140, property: unit.property),
      insert(:feature, name: "Pool View", price: 30, property: unit.property),
      insert(:feature, name: "Park View", price: 30, property: unit.property)
    ]

    {:ok, fp} =
      Properties.create_floor_plan(
        ClientSchema.new("dasmen", %{
          "name" => "Something",
          "feature_ids" => Enum.map(features, & &1.id),
          "property_id" => unit.property.id
        })
      )

    total = Enum.reduce(features, 0, &Decimal.add(&1.price, Decimal.new(&2)))
    {:ok, [unit: unit, features: features, floor_plan: fp, total: total]}
  end

  test "returns 0 for unit_rent when no features", %{unit: unit} do
    assert Properties.unit_rent(unit) == Decimal.new(0)
  end

  test "calculates unit rent", %{unit: unit, features: features, total: total} do
    Properties.update_unit(
      unit.id,
      %{"feature_ids" => Enum.map(features, & &1.id)}
    )

    # ClientSchema.new("dasmen", %{"feature_ids" => Enum.map(features, & &1.id)})

    assert Properties.unit_rent(unit) == total
  end

  test "calculates unit rent with floor plans", %{unit: unit, floor_plan: fp, total: total} do
    {:ok, unit} = Properties.update_unit(unit.id, %{"floor_plan_id" => fp.id})
    # Properties.update_unit(unit.id, ClientSchema.new("dasmen", %{"floor_plan_id" => fp.id}))

    assert Properties.unit_rent(unit) == total
  end
end
