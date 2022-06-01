defmodule AppCount.Repo.Migrations.CreateAccountingReportTemplates do
  use Ecto.Migration

  def change do
    create table(:accounting__report_templates) do
      add :name, :string, null: false
      add :groups, :jsonb, null: false, default: "[]"
      add :is_balance, :boolean, default: false, null: false
      timestamps()
    end

  end
end
