defmodule AppCount.Repo.Migrations.AddPaymentSessionsTransactionId do
  use Ecto.Migration

  def change do
    alter table("accounting__payment_sessions") do
      add :transaction_id, :string
    end
  end
end
