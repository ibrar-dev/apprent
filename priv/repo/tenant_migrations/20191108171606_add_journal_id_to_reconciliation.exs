defmodule AppCount.Repo.Migrations.AddJournalIdToReconciliation do
  use Ecto.Migration

  def change do
      alter table(:accounting__reconciliations) do
        add :journal_id, references(:accounting__journal_entries)
      end
  end
end
