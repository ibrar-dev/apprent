defmodule AppCount.Properties.Occupancy do
  use Ecto.Schema
  import Ecto.Changeset

  schema "properties__occupancies" do
    belongs_to :tenant, Module.concat(["AppCount.Tenants.Tenant"])
    belongs_to :lease, Module.concat(["AppCount.Leases.Lease"])

    timestamps()
  end

  @doc false
  def changeset(leasing, attrs) do
    leasing
    |> cast(attrs, [:tenant_id, :lease_id])
    |> validate_required([:tenant_id, :lease_id])
    |> unique_constraint(:unique, name: :properties__occupancies_tenant_id_lease_id_index)
  end
end
