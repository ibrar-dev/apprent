defmodule AppCount.Repo.Migrations.RestructureClientsFeatures do
  use Ecto.Migration

  def change do
    execute "TRUNCATE clients_features"
    alter table(:clients_features) do
      remove :flag_name
      add :module_id, references(:modules, on_delete: :delete_all), null: false
    end

    rename table(:clients_features), to: table(:clients_modules)

    create index(:clients_modules, [:module_id])
  end
end
