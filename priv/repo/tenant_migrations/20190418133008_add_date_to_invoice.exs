defmodule AppCount.Repo.Migrations.AddDateToInvoice do
  use Ecto.Migration

  def change do
    alter table(:accounting__invoices) do
      add :date, :date, null: true
    end
  end
end
