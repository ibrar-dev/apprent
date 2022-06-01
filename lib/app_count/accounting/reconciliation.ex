defmodule AppCount.Accounting.Reconciliation do
  use Ecto.Schema
  import Ecto.Changeset

  schema "accounting__reconciliations" do
    field :clear_date, :date
    field :memo, :string
    belongs_to :payment, Module.concat(["AppCount.Ledgers.Payment"])
    belongs_to :batch, Module.concat(["AppCount.Ledgers.Batch"])
    belongs_to :check, Module.concat(["AppCount.Accounting.Check"])
    belongs_to :journal, Module.concat(["AppCount.Accounting.JournalEntry"])

    belongs_to :reconciliation_posting,
               Module.concat(["AppCount.Accounting.ReconciliationPosting"])

    timestamps()
  end

  @doc false
  def changeset(reconciliation, attrs) do
    reconciliation
    |> cast(attrs, [
      :clear_date,
      :memo,
      :payment_id,
      :check_id,
      :batch_id,
      :journal_id,
      :reconciliation_posting_id
    ])
    |> unique_constraint(:journal_id)
    |> unique_constraint(:batch_id)
    |> unique_constraint(:payment_id)
    |> unique_constraint(:check_id)
    |> validate_required_inclusion
  end

  def validate_required_inclusion(changeset) do
    if Enum.any?([:batch_id, :check_id, :payment_id, :journal_id], &present?(changeset, &1)) do
      changeset
    else
      add_error(
        changeset,
        :batch_id,
        "One of these fields must be present: [batch_id, check_id, payment_id, journal_id]"
      )
    end
  end

  def present?(changeset, field) do
    value = get_field(changeset, field)
    value && value != ""
  end
end
