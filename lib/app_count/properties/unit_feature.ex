defmodule AppCount.Properties.UnitFeature do
  use Ecto.Schema
  import Ecto.Changeset

  schema "properties__unit_features" do
    belongs_to :unit, Module.concat(["AppCount.Properties.Unit"])
    belongs_to :feature, Module.concat(["AppCount.Properties.Feature"])

    timestamps()
  end

  @doc false
  def changeset(unit_feature, attrs) do
    unit_feature
    |> cast(attrs, [:unit_id, :feature_id])
    |> validate_required([:unit_id, :feature_id])
    |> unique_constraint(:parameters, name: :properties__unit_features_unit_id_feature_id_index)
  end
end
