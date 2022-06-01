defmodule AppCount.Materials.Order do
  use Ecto.Schema
  import Ecto.Changeset

  schema "materials__orders" do
    field :number, :string
    field :status, :string, default: "pending"
    field :tax, :decimal, default: 0
    field :shipping, :decimal, default: 0
    field :history, :map
    has_many :items, Module.concat(["AppCount.Materials.OrderItem"])

    timestamps()
  end

  @doc false
  def changeset(order, attrs) do
    order
    |> cast(attrs, [:number, :status, :tax, :shipping, :history])
    |> validate_required([:number, :status, :history, :tax, :shipping])
  end
end
