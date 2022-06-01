defmodule AppCount.Vendors.Vendor do
  use Ecto.Schema
  import Ecto.Changeset

  @required [:name, :email]
  @fields @required ++
            [:phone, :email, :address, :contact_name, :active, :completion_comment, :rating]

  schema "vendors__vendors" do
    field :address, :string
    field :email, :string
    field :name, :string
    field :phone, :string
    field :contact_name, :string
    field :active, :boolean
    field :rating, :integer
    field :completion_comment, :string

    many_to_many(:categories, AppCount.Vendors.Category, join_through: AppCount.Vendors.Skill)

    many_to_many(:properties, AppCount.Properties.Property,
      join_through: AppCount.Vendors.Property
    )

    timestamps()
  end

  def new(name, email) do
    %__MODULE__{name: name, email: email}
  end

  @doc false
  def changeset(vendor, attrs) do
    vendor
    |> cast(attrs, @fields)
    |> validate_required(@required)
    |> validate_inclusion(:rating, 1..5, message: "Out of Range: 1-5")
  end
end
