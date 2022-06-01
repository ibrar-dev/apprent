defmodule AppCount.Repo.Migrations.CreatePurchasesPurchaseOrderProject do
  use Ecto.Migration

  def change do
    create table(:purchases__purchase_order_projects) do
      add :name, :string, null: false
      add :open, :boolean, null: false
      add :property_id, references(:properties__properties), null: false
      add :admin_id, references(:admins__admins), null: false
      add :category_id, references(:vendors__categories), null: false
      timestamps()
    end
  end
end
