defmodule AppCount.Repo.Migrations.CreateUnitsDefaultLeaseCharges do
  use Ecto.Migration

  def change do
    create table(:units__default_lease_charges) do
      add :price, :integer, null: false
      add :history, :jsonb, default: "[]"
      add :default_charge, :boolean, default: true, null: false
      add :floor_plan_id, references(:properties__floor_plans, on_delete: :delete_all)
      add :account_id, references(:accounting__accounts, on_delete: :delete_all)

      timestamps()
    end

    create index(:units__default_lease_charges, [:floor_plan_id])
    create index(:units__default_lease_charges, [:account_id])
  end
end
