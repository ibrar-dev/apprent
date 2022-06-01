defmodule AppCount.Properties.Document do
  use Ecto.Schema
  import Ecto.Changeset
  use AppCount.EctoTypes.Attachment

  schema "properties__documents" do
    field :name, :string
    field :type, :string
    field :visible, :boolean
    attachment(:document)
    belongs_to :tenant, AppCount.Tenants.Tenant

    timestamps()
  end

  @doc false
  def changeset(document, attrs) do
    document
    |> cast(attrs, [:name, :tenant_id, :type, :visible])
    |> cast_attachment(:document)
    |> validate_required([:name, :tenant_id, :type])
  end
end
