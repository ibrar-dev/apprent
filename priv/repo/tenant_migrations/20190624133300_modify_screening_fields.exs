defmodule AppCount.Repo.Migrations.ModifyScreeningFields do
  use Ecto.Migration

  def change do
    alter table(:leases__screenings) do
      add :property_id, references(:properties__properties, on_delete: :delete_all), null: false
      add :person_id, references(:rent_apply__persons, on_delete: :delete_all)
      add :lease_id, references(:properties__leases, on_delete: :delete_all)
      add :rent, :decimal, null: false
      add :linked_orders, {:array, :string}, default: "{}", null: false
    end
    create constraint(:leases__screenings, :must_have_assoc, check: "person_id IS NOT NULL OR lease_id IS NOT NULL")
    create unique_index(:leases__screenings, [:tenant_id])
    create unique_index(:leases__screenings, [:person_id])
    create index(:leases__screenings, [:lease_id])
    create index(:leases__screenings, [:property_id])
  end
end
