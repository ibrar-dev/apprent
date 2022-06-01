defmodule AppCount.Repo.Migrations.FixLeasingChargesRefs do
  use Ecto.Migration

  def change do
    alter table(:leasing__charges) do
      remove :lease_id
      remove :charge_code_id
      add :lease_id, references(:leasing__leases, on_delete: :delete_all), null: false
      add :charge_code_id, references(:leasing__charge_codes, on_delete: :delete_all), null: false
    end

    create index(:leasing__charges, [:lease_id])
    create index(:leasing__charges, [:charge_code_id])
  end
end
