defmodule AppCount.Repo.Migrations.AddOccupancyRefToPayments do
  use Ecto.Migration

  def change do
    alter table(:accounting__payments) do
      add :lease_id, references(:leases__leases, on_delete: :nilify_all)
    end

    create index(:accounting__payments, [:lease_id])
  end
end
