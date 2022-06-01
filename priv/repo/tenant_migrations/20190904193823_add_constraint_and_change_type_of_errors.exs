defmodule AppCount.Repo.Migrations.AddConstraintAndChangeTypeOfErrors do
  use Ecto.Migration

  def change do
    drop unique_index(:accounting__budgets__lines, [:property_id, :month])

    alter table(:accounting__budgets__imports) do
      remove :errors, :jsonb
      add :errors, :jsonb, default: "[]", null: false
    end
    alter table(:maintenance__cards) do
      add :bypass_admin, :string, null: true
      add :bypass_date, :naive_datetime, null: true
    end
    create unique_index(:accounting__budgets__lines, [:account_id, :property_id, :month], name: :unique_month_year)
  end
end
