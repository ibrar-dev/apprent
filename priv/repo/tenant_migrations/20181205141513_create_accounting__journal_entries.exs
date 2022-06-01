defmodule AppCount.Repo.Migrations.CreateAccountingJournalEntries do
  use Ecto.Migration

  def change do
    create table(:accounting__journal_pages) do
      add :name, :string, null: false
      add :date, :date, null: false

      timestamps()
    end

    create table(:accounting__journal_entries) do
      add :amount, :decimal, null: false
      add :account_id, references(:accounting__accounts, on_delete: :delete_all), null: false
      add :property_id, references(:properties__properties, on_delete: :delete_all), null: false
      add :page_id, references(:accounting__journal_pages, on_delete: :delete_all), null: false
      add :is_credit, :boolean, default: false, null: false
      timestamps()
    end

    create index(:accounting__journal_entries, [:page_id])
    create index(:accounting__journal_entries, [:property_id])
    create index(:accounting__journal_entries, [:account_id])
  end
end
