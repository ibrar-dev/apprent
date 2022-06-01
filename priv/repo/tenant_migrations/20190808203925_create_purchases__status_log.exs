defmodule AppCount.Repo.Migrations.CreatePurchasesStatusLog do
  use Ecto.Migration

  def change do
    create table(:purchases__status_log) do
      add :purchase_order_id, references(:purchases__purchase_orders), null: false
      add :admin_permission_id, references(:purchases__admin_permissions), null: false
      add :approval_status, :string
      timestamps()
    end

  end
end
