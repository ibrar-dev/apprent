defmodule AppCount.Properties.Feature do
  use Ecto.Schema
  import Ecto.Changeset

  schema "properties__features" do
    field :name, :string
    field :price, :decimal
    field :start_date, :date
    field :stop_date, :date
    belongs_to :property, Module.concat(["AppCount.Properties.Property"])

    many_to_many(:units, Module.concat(["AppCount.Properties.Unit"]),
      join_through: AppCount.Properties.UnitFeature
    )

    timestamps()
  end

  @doc false
  def changeset(feature, attrs) do
    feature
    |> cast(attrs, [:name, :price, :property_id, :start_date, :stop_date])
    |> validate_required([:name, :price, :property_id])
    |> unique_constraint(:unique, name: :properties__features_property_id_name_index)
  end
end
