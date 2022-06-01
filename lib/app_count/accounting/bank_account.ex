defmodule AppCount.Accounting.BankAccount do
  use Ecto.Schema
  import Ecto.Changeset

  schema "accounting__bank_accounts" do
    field :name, :string
    field :bank_name, :string
    field :routing_number, :string
    field :account_number, :string
    field :address, :map

    many_to_many :properties,
                 AppCount.Properties.Property,
                 join_through: AppCount.Accounting.Entity

    belongs_to :account, AppCount.Accounting.Account
    has_many :checks, AppCount.Accounting.Check

    timestamps()
  end

  @doc false
  def changeset(bank_account, attrs) do
    bank_account
    |> cast(attrs, [:name, :bank_name, :address, :account_number, :routing_number, :account_id])
    |> validate_required([:name, :bank_name, :account_number, :routing_number, :account_id])
  end
end
