defmodule AppCount.Tenants.Vehicle do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tenants__vehicles" do
    field :color, :string
    field :license_plate, :string
    field :make_model, :string
    field :state, :string
    field :active, :boolean
    belongs_to :tenant, Module.concat(["AppCount.Tenants.Tenant"])

    timestamps()
  end

  @doc false
  def changeset(vehicle, attrs) do
    vehicle
    |> cast(attrs, [:make_model, :color, :license_plate, :state, :active, :tenant_id])
    |> validate_required([:make_model, :color, :license_plate, :state, :tenant_id])
  end
end
