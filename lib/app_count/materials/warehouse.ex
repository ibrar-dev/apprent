defmodule AppCount.Materials.Warehouse do
  use Ecto.Schema
  import Ecto.Changeset
  import AppCount.EctoTypes.Upload

  schema "materials__warehouses" do
    field :image, upload_type("appcount-maintenance:warehouse_images", "image", public: true)
    field :name, :string
    has_many :stocks, Module.concat(["AppCount.Materials.Stock"])

    timestamps()
  end

  @doc false
  def changeset(warehouse, attrs) do
    warehouse
    |> cast(attrs, [:name, :image])
    |> validate_required([:name])
  end
end
