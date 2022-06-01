defmodule AppCount.Repo.Migrations.MakeInvoiceTotalRequired do
  use Ecto.Migration

  def change do
    alter table(:accounting__invoices) do
      modify :amount, :decimal, null: false
    end
  end
end
