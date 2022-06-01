defmodule AppCount.Leasing.ExternalLease do
  use Ecto.Schema
  import Ecto.Changeset
  use AppCount.EctoTypes.Attachment

  schema "leasing__external_leases" do
    field :external_id, :string
    field :signature_id, :string
    field :parameters, :map
    field :provider, :string
    field :executed, :boolean
    field :archived, :boolean
    field :signators, :map
    attachment(:document)
    belongs_to :admin, AppCount.Admins.Admin
    belongs_to :unit, AppCount.Properties.Unit
    belongs_to :lease, AppCount.Leasing.Lease
    belongs_to :rent_application, AppCount.RentApply.RentApplication

    timestamps()
  end

  @doc false
  def changeset(external_lease, attrs) do
    external_lease
    |> cast(
      attrs,
      [
        :external_id,
        :signature_id,
        :signators,
        :parameters,
        :provider,
        :admin_id,
        :unit_id,
        :executed,
        :archived,
        :rent_application_id,
        :lease_id
      ]
    )
    |> cast_attachment(:document)
    |> validate_required([:provider, :unit_id])
  end
end
