defmodule AppCount.Properties.Package do
  use Ecto.Schema
  import Ecto.Changeset

  schema "properties__packages" do
    field :condition, :string
    field :last_emailed, :date
    field :status, :string
    field :type, :string
    field :carrier, :string
    field :notes, :string
    field :admin, :string
    field :reason, :string
    field :name, :string
    #    field :tenant_id, :integer
    field :tracking_number, :string
    belongs_to :tenant, Module.concat(["AppCount.Tenants.Tenant"])
    belongs_to :unit, Module.concat(["AppCount.Properties.Unit"])

    timestamps()
  end

  @doc false
  def changeset(package, attrs) do
    package
    |> cast(attrs, [
      :status,
      :condition,
      :type,
      :last_emailed,
      :unit_id,
      :carrier,
      :tracking_number,
      :reason,
      :admin,
      :notes,
      :name,
      :tenant_id
    ])
    |> validate_required([:status, :carrier, :unit_id, :admin])
  end
end
