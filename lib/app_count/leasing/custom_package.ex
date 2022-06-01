defmodule AppCount.Leasing.CustomPackage do
  use Ecto.Schema
  import Ecto.Changeset

  schema "leasing__custom_packages" do
    field :amount, :decimal
    field :notes, {:array, :map}
    belongs_to :renewal_package, Module.concat(["AppCount.Leasing.RenewalPackage"])
    belongs_to :lease, Module.concat(["AppCount.Leasing.Lease"])

    timestamps()
  end

  @doc false
  def changeset(custom_package, attrs) do
    custom_package
    |> cast(attrs, [:amount, :renewal_package_id, :lease_id, :notes])
    |> validate_required([:amount, :renewal_package_id, :lease_id])
    |> unique_constraint(:unique, name: :leases__custom_packages_renewal_package_id_lease_id_index)
  end
end
