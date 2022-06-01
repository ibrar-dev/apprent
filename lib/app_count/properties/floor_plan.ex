defmodule AppCount.Properties.FloorPlan do
  use Ecto.Schema
  import Ecto.Changeset

  schema "properties__floor_plans" do
    field :name, :string
    field :current_market_rent, :integer, virtual: true
    belongs_to :property, Module.concat(["AppCount.Properties.Property"])
    has_many :units, Module.concat(["AppCount.Properties.Unit"])
    has_many :default_charges, Module.concat(["AppCount.Units.DefaultLeaseCharge"])

    many_to_many :features,
                 Module.concat(["AppCount.Properties.Feature"]),
                 join_through: Module.concat(["AppCount.Properties.FloorPlanFeature"])

    timestamps()
  end

  @doc false
  def changeset(floor_plan, attrs) do
    floor_plan
    |> cast(attrs, [:name, :property_id])
    |> validate_required([:name, :property_id])
    |> unique_constraint(:unique_to_property,
      name: :properties__floor_plans_property_id_name_index
    )
  end
end
