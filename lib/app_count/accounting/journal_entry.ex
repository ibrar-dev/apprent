defmodule AppCount.Accounting.JournalEntry do
  use Ecto.Schema
  import Ecto.Changeset

  schema "accounting__journal_entries" do
    field :amount, :decimal
    field :is_credit, :boolean
    belongs_to :account, Module.concat(["AppCount.Accounting.Account"])
    belongs_to :property, Module.concat(["AppCount.Properties.Property"])
    belongs_to :page, Module.concat(["AppCount.Accounting.JournalPage"])
    timestamps()
  end

  @doc false
  def changeset(journal_entry, attrs) do
    journal_entry
    |> cast(attrs, [:amount, :is_credit, :account_id, :page_id, :property_id])
    |> validate_required([:amount, :account_id, :page_id, :property_id])
  end
end
