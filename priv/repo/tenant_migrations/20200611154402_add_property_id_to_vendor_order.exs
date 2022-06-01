defmodule AppCount.Repo.Migrations.AddPropertyIdToVendorOrder do
  use Ecto.Migration

  def change do
    alter table(:vendors__orders) do
      add :property_id, references(:properties__properties, on_delete: :delete_all)
    end

    create index(:vendors__orders, [:property_id])
  end
end
