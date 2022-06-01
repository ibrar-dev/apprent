defmodule AppCount.Materials.Inventory do
  use Ecto.Schema
  import Ecto.Changeset

  schema "materials__inventory" do
    field :inventory, :integer
    belongs_to :stock, Module.concat(["AppCount.Materials.Stock"])
    belongs_to :material, Module.concat(["AppCount.Materials.Material"])

    timestamps()
  end

  @doc false
  def changeset(inventory, attrs) do
    inventory
    |> cast(attrs, [:inventory, :stock_id, :material_id])
    |> validate_required([:inventory, :stock_id, :material_id])
  end
end
