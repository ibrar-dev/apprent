defmodule AppCount.Repo.Migrations.AddCreatedByToVendorOrders do
  use Ecto.Migration

  def change do
    alter table(:vendors__orders) do
      add :created_by, :string, null: true
      add :admin_id, references(:admins__admins, on_delete: :delete_all), null: true
    end

    alter table(:maintenance__material_logs) do
      add :returned, :jsonb, null: true
    end

    alter table(:maintenance__card_items) do
      add :vendor_id, references(:vendors__vendors, on_delete: :delete_all), null: true
    end
  end
end
