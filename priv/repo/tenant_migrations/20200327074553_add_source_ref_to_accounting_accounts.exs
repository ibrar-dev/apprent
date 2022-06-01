defmodule AppCount.Repo.Migrations.AddSourceRefToAccountingAccounts do
  use Ecto.Migration

  def change do
    alter table(:accounting__accounts) do
      add :source_id, references(:accounting__categories, on_delete: :delete_all)
    end

    create index(:accounting__accounts, [:source_id])
  end
end
