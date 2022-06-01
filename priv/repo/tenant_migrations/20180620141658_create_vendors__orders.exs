defmodule AppCount.Repo.Migrations.CreateVendorsOrders do
  use Ecto.Migration

  def change do
    create table(:vendors__orders) do
      add :status, :string, null: false
      add :vendor_id, references(:vendors__vendors, on_delete: :delete_all)
      add :category_id, references(:vendors__categories, on_delete: :delete_all)
      add :order_id, references(:maintenance__orders, on_delete: :delete_all)

      timestamps()
    end

    alter table(:maintenance__orders) do
      add :vendor_order_id, references(:vendors__orders, on_delete: :delete_all)
    end

  end
end
