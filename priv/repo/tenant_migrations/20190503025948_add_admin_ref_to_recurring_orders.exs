defmodule AppCount.Repo.Migrations.AddAdminRefToRecurringOrders do
  use Ecto.Migration

  def change do
    alter table(:maintenance__recurring_orders) do
      add :admin_id, references(:admins__admins, on_delete: :nothing)
    end
  end
end
