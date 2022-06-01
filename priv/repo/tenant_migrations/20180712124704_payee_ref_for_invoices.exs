defmodule AppCount.Repo.Migrations.PayeeRefForInvoices do
  use Ecto.Migration

  def change do
    alter table(:accounting__invoices) do
      add :payee_id, references(:accounting__payees, on_delete: :delete_all), null: false
      remove :from
    end

    create index(:accounting__invoices, [:payee_id])
  end
end
