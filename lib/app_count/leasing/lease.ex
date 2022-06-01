defmodule AppCount.Leasing.Lease do
  use Ecto.Schema
  import Ecto.Changeset
  use AppCount.EctoTypes.Attachment

  schema "leasing__leases" do
    field :date, :date
    field :end_date, :date
    field :no_renewal, :boolean, default: false
    field :renewal_admin, :string
    field :start_date, :date
    field :external_id, :string
    field :external_signature_id, :string
    field :pending_external_id, :string
    field :pending_external_signature_id, :string
    belongs_to :customer_ledger, AppCount.Ledgers.CustomerLedger
    belongs_to :unit, AppCount.Properties.Unit
    belongs_to :renewal_package, AppCount.Leasing.RenewalPackage

    has_many :tenancies, AppCount.Tenants.Tenancy,
      foreign_key: :customer_ledger_id,
      references: :customer_ledger_id

    attachment(:document)

    has_many :charges, AppCount.Leasing.Charge

    timestamps()
  end

  @doc false
  def changeset(lease, attrs) do
    lease
    |> cast(attrs, [
      :start_date,
      :end_date,
      :date,
      :renewal_admin,
      :no_renewal,
      :customer_ledger_id,
      :external_signature_id,
      :external_id,
      :pending_external_signature_id,
      :pending_external_id,
      :unit_id
    ])
    |> cast_attachment(:document)
    |> validate_required([:start_date, :end_date, :date, :customer_ledger_id, :unit_id])
    |> check_constraint(:lease_duration, name: :valid_duration)
  end
end
