defmodule AppCount.Properties.Region do
  use Ecto.Schema
  import Ecto.Changeset

  schema "properties__regions" do
    field :name, :string
    belongs_to :regional_supervisor, Module.concat(["AppCount.Admins.Admin"])
    has_many :properties, Module.concat(["AppCount.Properties.Property"])
    timestamps()
  end

  @doc false
  def changeset(region, attrs) do
    region
    |> cast(attrs, [:name, :regional_supervisor_id])
    |> validate_required([:name])
  end
end
