defmodule AppCount.Tenants.Pet do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tenants__pets" do
    field :breed, :string
    field :name, :string
    field :type, :string
    field :weight, :string
    field :active, :boolean
    belongs_to :tenant, Module.concat(["AppCount.Tenants.Tenant"])

    timestamps()
  end

  @doc false
  def changeset(pet, attrs) do
    pet
    |> cast(attrs, [:type, :breed, :weight, :name, :tenant_id, :active])
    |> validate_required([:type, :breed, :weight, :name, :tenant_id])
  end
end
