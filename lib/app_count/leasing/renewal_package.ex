defmodule AppCount.Leasing.RenewalPackage do
  use Ecto.Schema
  import Ecto.Changeset

  schema "leasing__renewal_packages" do
    field :min, :integer
    field :max, :integer
    field :base, :string
    field :amount, :decimal
    field :dollar, :boolean
    field :notes, {:array, :map}
    belongs_to :renewal_period, Module.concat(["AppCount.Leasing.RenewalPeriod"])
    has_many :custom_packages, Module.concat(["AppCount.Leasing.CustomPackage"])

    timestamps()
  end

  @doc false
  def changeset(renewal_package, attrs) do
    renewal_package
    |> cast(attrs, [:min, :max, :base, :amount, :dollar, :renewal_period_id, :notes])
    |> validate_required([:min, :max, :amount, :renewal_period_id])
    |> exclusion_constraint(:overlap,
      name: :min_max_overlap,
      message: "Conflicts with another renewal package"
    )
  end
end
