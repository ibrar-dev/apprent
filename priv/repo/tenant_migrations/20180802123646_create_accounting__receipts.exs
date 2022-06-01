defmodule AppCount.Repo.Migrations.CreateAccountingReceipts do
  use Ecto.Migration

  def change do
    create table(:accounting__receipts) do
      add :amount, :decimal, null: false
      add :charge_id, references(:accounting__charges, on_delete: :delete_all), null: false
      add :payment_id, references(:accounting__payments, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:accounting__receipts, [:charge_id, :payment_id])
  end
end
