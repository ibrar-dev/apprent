defmodule AppCount.Properties.FeaturesTest do
  use AppCount.DataCase
  import AppCount.TimeCop
  alias AppCount.Properties
  alias AppCount.Properties.Feature
  alias AppCount.Properties.FloorPlanFeature
  alias AppCount.Properties.UnitFeature
  alias AppCount.Core.ClientSchema
  use AppCount.Decimal
  @moduletag :features

  setup do
    property = insert(:property)
    features = Enum.map(1..5, fn _ -> insert(:feature, property: property) end)
    floor_plan = insert(:floor_plan, features: features)
    unit = insert(:unit, features: [hd(features)])
    {:ok, property: property, features: features, floor_plan: floor_plan, unit: unit}
  end

  test "update on same day", %{features: [feature | _]} do
    Properties.update_feature(
      feature.id,
      ClientSchema.new("dasmen", %{price: feature.price + 70})
    )

    updated = Repo.get(Feature, feature.id)
    assert Decimal.to_integer(updated.price) == feature.price + 70
    refute updated.stop_date
  end

  test "update on different day", %{
    features: [feature | _],
    property: property,
    floor_plan: floor_plan,
    unit: unit
  } do
    date = Timex.shift(AppCount.current_date(), days: 7)

    freeze date do
      Properties.update_feature(
        feature.id,
        ClientSchema.new("dasmen", %{price: feature.price + 30})
      )

      updated = Repo.get(Feature, feature.id, prefix: "dasmen")
      today = AppCount.current_date()
      assert updated.stop_date == today

      new_version =
        Repo.get_by(Feature, name: feature.name, start_date: today, property_id: property.id)

      assert new_version
      refute new_version.stop_date

      assert Repo.get_by(UnitFeature, [feature_id: updated.id, unit_id: unit.id], prefix: "dasmen")

      assert Repo.get_by(UnitFeature, [feature_id: new_version.id, unit_id: unit.id],
               prefix: "dasmen"
             )

      assert Repo.get_by(FloorPlanFeature, [feature_id: updated.id, floor_plan_id: floor_plan.id],
               prefix: "dasmen"
             )

      assert Repo.get_by(
               FloorPlanFeature,
               [feature_id: new_version.id, floor_plan_id: floor_plan.id],
               prefix: "dasmen"
             )
    end
  end
end
