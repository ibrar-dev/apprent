defmodule AppCount.Repo.Migrations.AddDatesAndBalanceToRconcilliationPosting do
  use Ecto.Migration

  def change do
    alter table("accounting__reconciliation_postings") do
      add :bank_account_id, references("accounting__bank_accounts")
      add :total_deposits, :numeric
      add :total_payments, :numeric
      add :start_date, :date
      add :is_posted, :boolean
      add :document_id, references(:data__uploads, on_delete: :nilify_all)
      modify :admin, :string
    end

    alter table("accounting__payments") do
      add :reconciliation_id, references("accounting__reconciliation_postings")
    end

    alter table("accounting__invoice_payments") do
      add :reconciliation_id, references("accounting__reconciliation_postings")
    end

  end
end
