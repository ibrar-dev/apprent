defmodule AppCount.Repo.Migrations.AddPaymentSessionInitiatedToPaymentSessions do
  use Ecto.Migration

  def change do
    alter table("accounting__payment_sessions") do
      add :started_at, :utc_datetime, nil: false
    end
  end
end
