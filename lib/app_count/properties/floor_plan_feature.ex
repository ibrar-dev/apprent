defmodule AppCount.Properties.FloorPlanFeature do
  use Ecto.Schema
  import Ecto.Changeset

  schema "properties__floor_plan_features" do
    belongs_to :feature, Module.concat(["AppCount.Properties.Feature"])
    belongs_to :floor_plan, Module.concat(["AppCount.Properties.FloorPlan"])

    timestamps()
  end

  @doc false
  def changeset(floor_plan_feature, attrs) do
    floor_plan_feature
    |> cast(attrs, [:feature_id, :floor_plan_id])
    |> validate_required([:feature_id, :floor_plan_id])
    |> unique_constraint(:unique,
      name: :properties_floor_plan_features_feature_id_floor_plan_id_index
    )
  end
end
