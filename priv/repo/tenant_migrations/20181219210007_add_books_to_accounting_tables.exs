defmodule AppCount.Repo.Migrations.AddBooksToAccountingTables do
  use Ecto.Migration

  def change do
    alter table(:accounting__journal_pages) do
      add :cash, :boolean, default: false, null: false
      add :accrual, :boolean, default: false, null: false
    end
  end
end
