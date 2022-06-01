defmodule AppCount.Repo.Migrations.AddIsDefaultToPaymentMethods do
  use Ecto.Migration

  def change do
    alter table("accounts__payment_sources") do
      add :is_default, :boolean, default: false
    end
  end
end
