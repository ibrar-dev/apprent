defmodule AppCount.Repo.Migrations.AddPaymentSessionsProcessorId do
  use Ecto.Migration

  def change do
    alter table("accounting__payment_sessions") do
      add :processor_id, :integer
    end
  end
end
