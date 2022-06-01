defmodule AppCount.Repo.Migrations.AddLeaseRefToChecks do
  use Ecto.Migration

  def change do
    alter table(:accounting__checks) do
      add :lease_id, references(:accounting__checks, on_delete: :delete_all)
    end

    create index(:accounting__checks, [:document_id])
    create index(:accounting__checks, [:lease_id])
  end
end
