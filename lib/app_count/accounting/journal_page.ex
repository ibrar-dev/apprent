defmodule AppCount.Accounting.JournalPage do
  use Ecto.Schema
  import Ecto.Changeset

  schema "accounting__journal_pages" do
    field(:date, :date)
    field(:name, :string)
    field(:cash, :boolean)
    field(:accrual, :boolean)
    field(:post_month, :date)
    has_many(:entries, Module.concat(["AppCount.Accounting.JournalEntry"]), foreign_key: :page_id)

    timestamps()
  end

  @doc false
  def changeset(journal_page, attrs) do
    journal_page
    |> cast(attrs, [:name, :date, :cash, :accrual, :post_month])
    |> validate_required([:name, :post_month, :date])
    |> check_constraint(:post_month, name: :valid_post_month)
  end
end
