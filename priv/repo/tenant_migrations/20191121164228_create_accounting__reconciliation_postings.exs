defmodule AppCount.Repo.Migrations.CreateAccountingReconciliationPostings do
  use Ecto.Migration

  def change do
    create table(:accounting__reconciliation_postings) do
      add :date, :date
      add :admin, :integer

      timestamps()
    end

  end
end
