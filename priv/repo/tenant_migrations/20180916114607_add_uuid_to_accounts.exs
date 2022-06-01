defmodule AppCount.Repo.Migrations.AddUUIDToAccounts do
  use Ecto.Migration

  def change do
    alter table(:accounts__accounts) do
      add :uuid, :uuid, default: fragment("uuid_generate_v4()"), null: false
    end

    create unique_index(:accounts__accounts, [:uuid])
  end
end
