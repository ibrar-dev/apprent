defmodule AppCount.Tenants.Tenancy do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tenants__tenancies" do
    field :actual_move_in, :date
    field :actual_move_out, :date
    field :expected_move_in, :date
    field :expected_move_out, :date
    field :start_date, :date
    field :external_id, :string
    field :notice_date, :date
    field :eviction_file_date, :date
    field :eviction_court_date, :string
    field :eviction_notes, :string
    field :external_balance, :decimal
    belongs_to :tenant, AppCount.Tenants.Tenant
    belongs_to :customer_ledger, AppCount.Ledgers.CustomerLedger
    belongs_to :unit, AppCount.Properties.Unit
    belongs_to :move_out_reason, AppCount.Settings.MoveOutReason

    has_many :leases, AppCount.Leasing.Lease,
      foreign_key: :customer_ledger_id,
      references: :customer_ledger_id

    timestamps()
  end

  @doc false
  def changeset(tenancy, attrs) do
    tenancy
    |> cast(
      attrs,
      [
        :actual_move_in,
        :actual_move_out,
        :expected_move_in,
        :expected_move_out,
        :start_date,
        :external_id,
        :tenant_id,
        :customer_ledger_id,
        :move_out_reason_id,
        :unit_id,
        :notice_date,
        :eviction_file_date,
        :eviction_court_date,
        :external_balance,
        :eviction_notes
      ]
    )
    |> validate_required([:start_date, :tenant_id, :customer_ledger_id, :unit_id])
    |> unique_constraint([:external_id])
  end
end
