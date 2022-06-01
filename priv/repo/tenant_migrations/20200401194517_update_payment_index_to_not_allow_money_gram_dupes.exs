defmodule AppCount.Repo.Migrations.UpdatePaymentIndexToNotAllowMoneyGramDupes do
  use Ecto.Migration

  def change do
    drop unique_index(:accounting__payments, [:transaction_id])
    create unique_index(:accounting__payments, [:transaction_id], where: "description = 'Money Order' or description = 'MoneyGram Payment'")
  end
end
