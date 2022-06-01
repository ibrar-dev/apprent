defmodule AppCount.Repo.Migrations.AddPaymentSessionsAgreementText do
  use Ecto.Migration

  def change do
    alter table("accounting__payment_sessions") do
      add :agreement_text, :text, default: ""
      add :total_amount_in_cents, :integer, default: 0
      add :response_from_adapter, :text, default: ""
      add :accounting_notified_at, :utc_datetime
      add :yardi_notified_at, :utc_datetime
      add :originating_device, :string
    end
  end
end
