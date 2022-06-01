defmodule AppCount.Repo.Migrations.InvoiceDateRequired do
  use Ecto.Migration

  def change do
    alter table(:accounting__invoices) do
      modify :date, :date, null: false
    end
  end
end
