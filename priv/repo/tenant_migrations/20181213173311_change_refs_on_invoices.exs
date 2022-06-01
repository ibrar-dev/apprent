defmodule AppCount.Repo.Migrations.ChangeRefsOnInvoices do
  use Ecto.Migration

  def change do
    alter table(:accounting__invoices) do
      add :payable_account_id, references(:accounting__accounts, on_delete: :delete_all), null: false
    end

    rename table(:accounting__invoices), :account_id, to: :cash_account_id
  end
end
