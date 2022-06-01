defmodule AppCount.Ledgers.Charge do
  use Ecto.Schema
  import Ecto.Changeset
  alias AppCount.Ledgers.Charge
  use AppCount.EctoTypes.Attachment

  schema "ledgers__charges" do
    field(:amount, :decimal)
    field(:bill_date, :date)
    field(:description, :string)
    field(:status, :string)
    field(:admin, :string)
    field(:post_month, :date)
    field(:metadata, :map)
    field(:external_id, :string)
    belongs_to(:reversal, AppCount.Ledgers.Charge)
    belongs_to(:lease, AppCount.Leases.Lease)
    belongs_to(:charge, AppCount.Properties.Charge, foreign_key: :charge_id)
    belongs_to(:charge_code, AppCount.Ledgers.ChargeCode)
    belongs_to(:nsf, AppCount.Ledgers.Payment)
    has_many(:receipts, AppCount.Accounting.Receipt)
    has_one(:reversed, AppCount.Ledgers.Charge, foreign_key: :reversal_id)
    belongs_to(:customer_ledger, AppCount.Ledgers.CustomerLedger)
    attachment(:image)

    timestamps()
  end

  @doc false
  def changeset(%Charge{} = charge, attrs) do
    charge
    |> cast(
      attrs,
      [
        :amount,
        :status,
        :charge_id,
        :charge_code_id,
        :lease_id,
        :description,
        :reversal_id,
        :bill_date,
        :post_month,
        :admin,
        :nsf_id,
        :metadata,
        :external_id,
        :customer_ledger_id
      ]
    )
    |> cast_attachment(:image)
    |> validate_required([:amount, :status, :charge_code_id, :post_month, :bill_date])
    |> unique_constraint(:reversal_id)
    |> unique_constraint(:nsf_id)
    |> check_constraint(:non_zero, name: :accounting_charges_non_zero)
    |> check_constraint(:post_month, name: :valid_post_month)
  end
end
