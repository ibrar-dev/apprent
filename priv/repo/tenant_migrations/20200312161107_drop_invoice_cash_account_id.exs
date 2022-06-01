defmodule AppCount.Repo.Migrations.DropInvoiceCashAccountId do
  use Ecto.Migration

  def change do
    alter table(:accounting__invoices) do
      remove :cash_account_id
    end
  end
end
