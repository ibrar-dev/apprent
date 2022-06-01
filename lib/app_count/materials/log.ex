defmodule AppCount.Materials.Log do
  use Ecto.Schema
  import Ecto.Changeset

  schema "materials__logs" do
    field :quantity, :integer
    field :admin, :string
    field :returned, :map
    belongs_to(:material, Module.concat(["AppCount.Materials.Material"]))
    belongs_to(:stock, Module.concat(["AppCount.Materials.Stock"]))
    belongs_to(:property, Module.concat(["AppCount.Properties.Property"]))

    timestamps()
  end

  @doc false
  def changeset(material_log, attrs) do
    material_log
    |> cast(attrs, [:property_id, :admin, :stock_id, :quantity, :material_id, :returned])
    |> validate_required([:property_id, :admin, :stock_id, :quantity, :material_id])
  end
end
