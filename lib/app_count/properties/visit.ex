defmodule AppCount.Properties.Visit do
  use Ecto.Schema
  import Ecto.Changeset

  schema "properties__visits" do
    field :description, :string
    field :admin, :string
    field :delinquency, :naive_datetime
    belongs_to :tenant, Module.concat(["AppCount.Tenants.Tenant"])
    belongs_to :property, Module.concat(["AppCount.Properties.Property"])

    timestamps()
  end

  @doc false
  def changeset(visit, attrs) do
    visit
    |> cast(attrs, [:description, :tenant_id, :property_id, :admin, :delinquency])
    |> validate_required([:description, :admin, :tenant_id, :property_id])
  end
end
