defmodule AppCount.Repo.Migrations.AddLeaseRefToCharges do
  use Ecto.Migration

  def change do
    alter table(:accounting__charges) do
      remove :tenant_id
      add :lease_id, references(:properties__leases, on_delete: :delete_all), null: false
    end

    create index(:accounting__charges, [:lease_id])
  end
end
