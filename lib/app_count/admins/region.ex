defmodule AppCount.Admins.Region do
  @moduledoc """
  Region is a group of Properties
  Most Regions have only one Property
  But some have multiple Properties
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias AppCount.Admins.Region

  schema "admins__regions" do
    field(:name, :string)
    field(:resources, {:array, :string}, default: [])
    has_many(:permissions, Module.concat(["AppCount.Admins.Permission"]))
    has_many(:scopings, Module.concat(["AppCount.Properties.Scoping"]))

    many_to_many(:admins, Module.concat(["AppCount.Admins.Admin"]),
      join_through: Module.concat(["AppCount.Admins.Permission"])
    )

    many_to_many(
      :properties,
      Module.concat(["AppCount.Properties.Property"]),
      join_through: Module.concat(["AppCount.Properties.Scoping"])
    )

    timestamps()
  end

  @doc false
  def changeset(%Region{} = region, attrs) do
    region
    |> cast(attrs, [:name, :resources])
    |> validate_required([:name, :resources])
    |> unique_constraint(:name, name: :admins_regions_name_index)
  end
end
