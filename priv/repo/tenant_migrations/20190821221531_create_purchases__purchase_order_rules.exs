defmodule AppCount.Repo.Migrations.CreatePurchasesPurchaseOrderRules do
  use Ecto.Migration

  def change do
    create table(:purchases__purchase_order_rules) do
      add :item_id, references(:purchases__items)
      add :property_id, references(:properties__properties)
      add :vendor_id, references(:accounting__payees)
      add :admin_id, references(:admins__admins)
      add :max_amount, :integer
      timestamps()
    end
  end
end
