defmodule AppCount.Accounting.Receipt do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:id, :amount]}

  schema "accounting__receipts" do
    field :amount, :decimal
    field :start_date, :date
    field :stop_date, :date
    belongs_to :charge, Module.concat(["AppCount.Ledgers.Charge"])
    belongs_to :account, Module.concat(["AppCount.Accounting.Account"])
    belongs_to :payment, Module.concat(["AppCount.Ledgers.Payment"])
    belongs_to :concession, Module.concat(["AppCount.Ledgers.Charge"])

    timestamps()
  end

  @doc false
  def changeset(receipt, attrs) do
    receipt
    |> cast(attrs, [
      :amount,
      :charge_id,
      :payment_id,
      :concession_id,
      :account_id,
      :start_date,
      :stop_date
    ])
    |> validate_required([:amount])
    |> unique_constraint(:unique, name: :accounting__receipts_charge_id_payment_id_index)
    |> unique_constraint(:unique, name: :accounting__receipts_charge_id_concession_id_index)
    |> check_constraint(:must_have_credit, name: :must_have_credit)
    |> check_constraint(:must_have_account, name: :must_have_account)
    |> check_constraint(:valid_date_range, name: :valid_date_range)
  end
end
