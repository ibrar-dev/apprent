defmodule AppCount.Materials.Material do
  use Ecto.Schema
  import Ecto.Changeset
  alias AppCount.Materials.Material
  import AppCount.EctoTypes.Upload

  schema "materials__materials" do
    field :cost, :decimal
    field :desired, :integer
    field :inventory, :integer
    field :name, :string
    field :ref_number, :string
    field :per_unit, :integer
    field :image, upload_type("appcount-maintenance:material_images", "image", public: true)
    #    belongs_to :stock, Module.concat(["AppCount.Materials.Stock"])
    belongs_to :type, Module.concat(["AppCount.Materials.Type"]), foreign_key: :type_id
    has_many :logs, Module.concat(["AppCount.Materials.Log"])

    many_to_many(:stocks, Module.concat(["AppCount.Materials.Stock"]),
      join_through: Module.concat(["AppCount.Materials.Inventory"])
    )

    timestamps()
  end

  @doc false
  def changeset(%Material{} = material, attrs) do
    material
    |> cast(attrs, [:name, :cost, :inventory, :desired, :type_id, :ref_number, :per_unit, :image])
    |> validate_required([:name, :cost, :inventory, :desired, :type_id, :ref_number])
    |> unique_constraint(:stock_id_ref_number,
      name: :maintenance_materials_stock_id_ref_number_index
    )
    |> unique_constraint(:stock_id_name, name: :maintenance_materials_stock_id_name_index)
  end
end
