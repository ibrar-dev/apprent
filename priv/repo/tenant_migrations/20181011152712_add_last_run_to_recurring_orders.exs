defmodule AppCount.Repo.Migrations.AddLastRunToRecurringOrders do
  use Ecto.Migration

  def change do
    alter table(:maintenance__recurring_orders) do
      add :last_run, :integer
      add :next_run, :integer
    end
  end
end
