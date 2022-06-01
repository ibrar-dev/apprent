defmodule AppCount.Repo.Migrations.CreateAccountingPaymentSessions do
  use Ecto.Migration

  def change do
  create table(:accounting__payment_sessions) do
      add :amount_in_cents, :integer, default: 0
      add :payment_confirmed_at, :utc_datetime
      add :account_id, :integer
      add :payment_source_id, :integer
      timestamps()
    end
  end
end
