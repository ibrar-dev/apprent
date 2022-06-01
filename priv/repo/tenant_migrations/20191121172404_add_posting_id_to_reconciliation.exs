defmodule AppCount.Repo.Migrations.AddPostingIdToReconciliation do
  use Ecto.Migration

  def change do
    alter table(:accounting__reconciliations) do
      add :posting_id, references(:accounting__reconciliation_postings)
    end
  end

end