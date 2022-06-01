defmodule AppCount.Repo.Migrations.AddsPaymentSessionMessage do
  use Ecto.Migration

  def change do
    alter table(:accounting__payment_sessions) do
      add :message, :text, default: ""
    end
  end
end
