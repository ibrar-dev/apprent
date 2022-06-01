defmodule AppCount.Repo.Migrations.AddSurchargeInCentsToPaymentSessions do
  use Ecto.Migration

  def change do
   alter table("accounting__payment_sessions") do
      add :surcharge_in_cents, :integer
    end
  end
end
