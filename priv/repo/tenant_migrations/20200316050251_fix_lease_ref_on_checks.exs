defmodule AppCount.Repo.Migrations.FixLeaseRefOnChecks do
  use Ecto.Migration

  def change do
    alter table(:accounting__checks) do
      remove :lease_id, references(:accounting__checks, on_delete: :delete_all)
      add :lease_id, references(:leases__leases, on_delete: :delete_all)
    end

    create index(:accounting__checks, [:lease_id])
  end
end
