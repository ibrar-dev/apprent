defmodule AppCount.Repo.Migrations.ClientFeatures do
  use Ecto.Migration

  def change do
    create table(:clients_features) do
      add :flag_name, :string, null: false
      add :client_id, references(:clients, on_delete: :delete_all), null: false
      add :enabled, :boolean, null: false, default: false
    end

    create unique_index(:clients_features, [:flag_name, :client_id])
  end
end
