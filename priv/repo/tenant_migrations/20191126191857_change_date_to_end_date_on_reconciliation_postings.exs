defmodule AppCount.Repo.Migrations.ChangeDateToEndDateOnReconciliationPostings do
  use Ecto.Migration

  def change do
    rename table(:accounting__reconciliation_postings), :date, to: :end_date
    rename table(:accounting__reconciliations), :posting_id, to: :reconciliation_posting_id
  end
end
