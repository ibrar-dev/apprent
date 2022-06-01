defmodule AppCount.Repo.Migrations.NoEverlapDatesReconciliationPostings do
  use Ecto.Migration

  def change do
    exclude = ~s|gist (bank_account_id WITH =, daterange("start_date", "end_date") WITH &&)|
    create constraint(:accounting__reconciliation_postings, :reocniliation_overlap, exclude: exclude)
    create unique_index(:accounting__reconciliations, [:journal_id])
    create unique_index(:accounting__reconciliations, [:payment_id])
    create unique_index(:accounting__reconciliations, [:batch_id])
    create unique_index(:accounting__reconciliations, [:check_id])
  end

end
