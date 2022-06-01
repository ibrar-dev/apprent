defmodule AppCount.Properties.FloorPlansTest do
  use AppCount.DataCase
  alias AppCount.Properties
  alias AppCount.Properties.FloorPlan
  alias AppCount.Core.ClientSchema

  setup do
    property = insert(:property)
    features = Enum.map(1..5, fn _ -> insert(:feature, property: property) end)
    {:ok, property: property, features: features}
  end

  test "list_floor_plans works", context do
    Repo.delete_all(Properties.FloorPlan, prefix: "dasmen")

    Properties.create_floor_plan(
      ClientSchema.new("dasmen", %{
        "property_id" => context.property.id,
        "name" => "Presidential",
        "feature_ids" => Enum.map(context.features, & &1.id)
      })
    )

    Properties.create_floor_plan(
      ClientSchema.new("dasmen", %{
        "property_id" => context.property.id,
        "name" => "Half Presidential",
        "feature_ids" =>
          Enum.map(context.features, & &1.id)
          |> Enum.take(2)
      })
    )

    plans =
      Properties.list_floor_plans(
        ClientSchema.new("dasmen", %{id: 1, roles: MapSet.new(["Super Admin"])})
      )

    assert length(plans) == 2
  end

  test "create_floor_plan works", context do
    {:ok, fp} =
      Properties.create_floor_plan(
        ClientSchema.new("dasmen", %{
          "property_id" => context.property.id,
          "name" => "Presidential",
          "feature_ids" => Enum.map(context.features, & &1.id)
        })
      )

    loaded = Repo.preload(fp, :features)
    assert loaded.name == "Presidential"
    assert loaded.property_id == context.property.id
    assert length(loaded.features) == length(context.features)
  end

  test "update_floor_plan works", context do
    fp = insert(:floor_plan)
    loaded = Repo.preload(fp, :features)
    feature_ids = Enum.map(context.features, & &1.id)
    assert Enum.empty?(loaded.features)

    Properties.update_floor_plan(
      fp.id,
      ClientSchema.new("dasmen", %{"name" => "Full", "feature_ids" => feature_ids})
    )

    loaded =
      Repo.get(FloorPlan, fp.id, prefix: "dasmen")
      |> Repo.preload(:features)

    assert loaded.name == "Full"
    assert length(loaded.features) == length(context.features)

    Properties.update_floor_plan(
      fp.id,
      ClientSchema.new("dasmen", %{"feature_ids" => Enum.take(feature_ids, 3)})
    )

    new_loaded =
      Repo.get(FloorPlan, fp.id, prefix: "dasmen")
      |> Repo.preload(:features)

    assert length(new_loaded.features) == 3
  end
end
