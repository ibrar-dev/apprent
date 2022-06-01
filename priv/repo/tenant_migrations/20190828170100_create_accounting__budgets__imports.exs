defmodule AppCount.Repo.Migrations.CreateAccountingBudgetsImports do
  use Ecto.Migration

  def change do
    create table(:accounting__budgets__imports) do
      add :document_id, references(:data__uploads, on_delete: :nilify_all)
      add :status, :string, null: false, default: "pending"
      add :errors, :jsonb, null: false, default: "{}"
      add :admin_id, references(:admins__admins, on_delete: :nilify_all), null: false
      add :property_id, references(:properties__properties, on_delete: :delete_all), null: false

      timestamps()
    end

  end
end
