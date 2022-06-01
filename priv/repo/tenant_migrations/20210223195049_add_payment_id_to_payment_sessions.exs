defmodule AppCount.Repo.Migrations.AddPaymentIdToPaymentSessions do
  use Ecto.Migration

  def change do
    alter table("accounting__payment_sessions") do
      add :payment_id, :integer, null: true, default: nil
    end
  end
end
