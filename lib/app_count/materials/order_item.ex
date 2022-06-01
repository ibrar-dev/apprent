defmodule AppCount.Materials.OrderItem do
  use Ecto.Schema
  import Ecto.Changeset

  schema "materials__orders_items" do
    field :quantity, :integer
    field :status, :string, default: "pending"
    field :cost, :decimal, default: 0
    belongs_to :material, Module.concat(["AppCount.Materials.Material"])
    belongs_to :order, Module.concat(["AppCount.Materials.Order"])

    timestamps()
  end

  @doc false
  def changeset(order_item, attrs) do
    order_item
    |> cast(attrs, [:quantity, :status, :cost, :material_id, :order_id])
    |> validate_required([:quantity, :status, :material_id, :cost])
  end
end
