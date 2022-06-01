defmodule AppCount.Accounting.ReconciliationPosting do
  use Ecto.Schema
  import Ecto.Changeset
  use AppCount.EctoTypes.Attachment

  schema "accounting__reconciliation_postings" do
    field :admin, :string
    field :end_date, :date
    field :start_date, :date
    field :total_payments, :decimal
    field :total_deposits, :decimal
    field :is_posted, :boolean, default: false
    belongs_to :bank_account, Module.concat(["AppCount.Accounting.BankAccount"])
    has_many :transactions, Module.concat(["AppCount.Accounting.Reconciliation"])
    attachment(:document)
    timestamps()
  end

  @doc false
  def changeset(reconciliation_posting, attrs) do
    reconciliation_posting
    |> cast(attrs, [
      :admin,
      :is_posted,
      :bank_account_id,
      :total_payments,
      :total_deposits,
      :start_date,
      :end_date
    ])
    |> cast_attachment(:document)
    |> validate_required([
      :bank_account_id,
      :total_payments,
      :total_deposits,
      :start_date,
      :end_date
    ])
    |> exclusion_constraint(:reocniliation_overlap,
      name: :reconcilaton_date_overlap,
      message: "Period overlaps with another reconciliation"
    )
  end
end
