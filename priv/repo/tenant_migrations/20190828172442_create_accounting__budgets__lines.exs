defmodule AppCount.Repo.Migrations.CreateAccountingBudgetsLines do
  use Ecto.Migration

  def change do
    create table(:accounting__budgets__lines) do
      add :month, :date, null: false
      add :amount, :decimal, null: false
      add :closed, :boolean, null: false, default: true
      add :history, :jsonb, null: false, default: "{}"
      add :property_id, references(:properties__properties), null: false
      add :admin_id, references(:admins__admins), null: false
      add :account_id, references(:accounting__accounts), null: false
      add :import_id, references(:accounting__budgets__imports), null: true

      timestamps()
    end
    create index(:accounting__budgets__lines, [:property_id])
    create index(:accounting__budgets__lines, [:admin_id])
    create index(:accounting__budgets__lines, [:account_id])
    create index(:accounting__budgets__lines, [:import_id])
    create index(:accounting__budgets__imports, [:admin_id])
    create index(:accounting__budgets__imports, [:property_id])
    create unique_index(:accounting__budgets__lines, [:property_id, :month])
  end
end
