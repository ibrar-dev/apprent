defmodule AppCount.Repo.Migrations.AddsPaymentSessionFailedAt do
  use Ecto.Migration

  def change do
    alter table(:accounting__payment_sessions) do
      add :failed_at, :utc_datetime
      add :ip_address, :string
    end
  end
end
