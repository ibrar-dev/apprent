defmodule AppCount.Repo.Migrations.CreatePurchasesPurchaseOrders do
  use Ecto.Migration

  def change do
    create table(:purchases__purchase_orders) do
      add :admin_id, references(:admins__admins), null: false
      add :order_date, :date
      add :vendor_id, references(:accounting__payees), null: false
      add :unit_id, references(:properties__units)
      add :note, :string
      add :property_id, references(:properties__properties), null: false
      add :work_order_id, references(:maintenance__orders)
      add :vendor_order_id, references(:vendors__orders)
      add :document_id, references(:data__uploads, on_delete: :delete_all)
      add :job_name, :string
      add :type, :string, default: "purchase order"
      add :closed, :boolean, default: false
      add :ordered, :boolean, default: false
      add :number, :string, null: false
      timestamps()
    end
    create unique_index(:purchases__purchase_orders, [:number])
  end
end
