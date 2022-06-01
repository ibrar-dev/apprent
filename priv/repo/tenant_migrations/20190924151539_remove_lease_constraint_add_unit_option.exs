defmodule AppCount.Repo.Migrations.RemoveLeaseConstraintAddUnitOption do
  use Ecto.Migration

  def change do
    alter table(:maintenance__cards) do
      modify :lease_id, references(:leases__leases, on_delete: :delete_all), null: true
      add :unit_id, references(:properties__units, on_delete: :delete_all), null: true
    end
    create constraint(:maintenance__cards, :must_have_unit_or_lease, check: "lease_id IS NOT NULL or unit_id IS NOT NULL")
  end
end
