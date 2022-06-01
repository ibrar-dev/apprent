defmodule AppCount.Repo.Migrations.CreateMaintenanceOpenHistory do
  use Ecto.Migration

  def change do
    create table(:maintenance__open_history) do
      add :open, :integer, null: false
      add :property_id, references(:properties__properties, on_delete: :delete_all), null: false

      timestamps()
    end

  end
end
