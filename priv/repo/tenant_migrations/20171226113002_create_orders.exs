defmodule AppCount.Repo.Migrations.CreateOrders do
  use Ecto.Migration

  def change do
    create table(:maintenance__orders) do
      add :tenant_id, references(:properties__tenants, on_delete: :delete_all)
      add :unit_id, references(:properties__units, on_delete: :delete_all)
      add :status, :string, null: false
      add :has_pet, :boolean, default: false, null: false
      add :entry_allowed, :boolean, default: false, null: false
      add :priority, :integer, null: false, default: 0
      add :category_id, references(:maintenance__categories, on_delete: :delete_all), null: false
      add :property_id, references(:properties__properties, on_delete: :delete_all), null: false
      timestamps()
    end

    create index(:maintenance__orders, [:property_id])
    create index(:maintenance__orders, [:category_id])
    create index(:maintenance__orders, [:tenant_id])
    create index(:maintenance__orders, [:unit_id])
  end
end
