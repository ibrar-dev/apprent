defmodule AppCount.Materials.Stock do
  use Ecto.Schema
  import Ecto.Changeset
  alias AppCount.Materials.Stock
  import AppCount.EctoTypes.Upload

  schema "materials__stocks" do
    field :name, :string
    field :image, upload_type("appcount-maintenance:stock_images", "image", public: true)

    many_to_many :materials, Module.concat(["AppCount.Materials.Material"]),
      join_through: Module.concat(["AppCount.Materials.Inventory"])

    has_many :properties, Module.concat(["AppCount.Properties.Property"])
    belongs_to :warehouse, Module.concat(["AppCount.Materials.Warehouse"])

    timestamps()
  end

  @doc false
  def changeset(%Stock{} = stock, attrs) do
    stock
    |> cast(attrs, [:name, :image])
    |> validate_required([:name])
  end
end
