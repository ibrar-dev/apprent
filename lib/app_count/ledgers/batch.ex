defmodule AppCount.Ledgers.Batch do
  use Ecto.Schema
  import Ecto.Changeset

  schema "ledgers__batches" do
    field :date_closed, :date
    field :closed_by, :string
    field :memo, :string
    belongs_to :property, AppCount.Properties.Property
    belongs_to :bank_account, AppCount.Accounting.BankAccount
    has_many :payments, AppCount.Ledgers.Payment

    timestamps()
  end

  @doc false
  def changeset(batch, attrs) do
    batch
    |> cast(attrs, [:property_id, :date_closed, :closed_by, :inserted_at, :memo, :bank_account_id])
    |> validate_required([:property_id, :bank_account_id])
  end
end
