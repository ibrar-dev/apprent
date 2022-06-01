defmodule AppCount.Repo.Migrations.AddTermsToAccountingPayees do
  use Ecto.Migration

  def change do
    alter table(:accounting__payees) do
      add :due_period, :integer, default: 30
      add :consolidate_checks, :boolean, default: true
    end
  end
end
