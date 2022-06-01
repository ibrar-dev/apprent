defmodule AppCount.Repo.Migrations.AdjustVendorOrdersAndMaintenanceOrders do
  use Ecto.Migration

  def change do
      alter table(:vendors__orders) do
        add :has_pet, :boolean, default: false, null: false
        add :entry_allowed, :boolean, default: false, null: false
      end

      alter table(:maintenance__orders) do
        add :created_by, :string, null: true
      end

  end
end
