defmodule AppCount.Materials.Type do
  use Ecto.Schema
  import Ecto.Changeset
  alias AppCount.Materials.Type

  schema "materials__types" do
    field :name, :string
    has_many :materials, Module.concat(["AppCount.Materials.Material"]), foreign_key: :type_id

    timestamps()
  end

  @doc false
  def changeset(%Type{} = material_type, attrs) do
    material_type
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end
end
