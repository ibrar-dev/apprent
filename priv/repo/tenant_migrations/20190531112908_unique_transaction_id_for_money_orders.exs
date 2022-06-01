defmodule AppCount.Repo.Migrations.UniqueTransactionIdForMoneyOrders do
  use Ecto.Migration

  def change do
    create unique_index(:accounting__payments, [:transaction_id], where: "description = 'Money Order'")
  end
end
