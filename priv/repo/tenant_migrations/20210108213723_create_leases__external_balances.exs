defmodule AppCount.Repo.Migrations.CreateLeasesExternalBalances do
  use Ecto.Migration

  def change do
    create table(:leases__external_balances) do
      add :balance, :decimal, null: false
      add :lease_id, references(:leases__leases, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:leases__external_balances, [:lease_id])
  end
end
