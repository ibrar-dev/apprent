defmodule AppCount.Repo.Migrations.AddPreviousAuthToPaymentSources do
  use Ecto.Migration

  def change do
    alter table("accounts__payment_sources") do
      add :original_network_transaction_id, :string, null: true
      add :original_auth_amount_in_cents, :integer, default: 0
    end
  end
end
