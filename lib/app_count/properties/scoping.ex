defmodule AppCount.Properties.Scoping do
  use Ecto.Schema
  import Ecto.Changeset
  alias AppCount.Properties.Scoping

  schema "properties__scopings" do
    belongs_to(:region, Module.concat(["AppCount.Admins.Region"]))
    belongs_to(:property, Module.concat(["AppCount.Properties.Property"]))

    timestamps()
  end

  @doc false
  def changeset(%Scoping{} = scoping, attrs) do
    scoping
    |> cast(attrs, [:region_id, :property_id])
    |> validate_required([:region_id, :property_id])
    |> unique_constraint(:unique, name: :properties__scopings_property_id_region_id_index)
  end
end
