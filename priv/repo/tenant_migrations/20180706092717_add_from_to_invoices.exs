defmodule AppCount.Repo.Migrations.AddFromToInvoices do
  use Ecto.Migration

  def change do
    alter table(:accounting__invoices) do
      add :from, :string, null: false
    end
  end
end
