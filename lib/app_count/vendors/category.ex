defmodule AppCount.Vendors.Category do
  use Ecto.Schema
  import Ecto.Changeset

  schema "vendors__categories" do
    field :name, :string

    many_to_many(:vendors, Module.concat(["AppCount.Vendors.Vendor"]),
      join_through: AppCount.Vendors.Skill
    )

    timestamps()
  end

  def new(name) do
    %__MODULE__{name: name}
  end

  @doc false
  def changeset(category, attrs) do
    category
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
