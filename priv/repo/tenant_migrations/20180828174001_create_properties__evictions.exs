defmodule AppCount.Repo.Migrations.CreatePropertiesEvictions do
  use Ecto.Migration

  def change do
    create table(:properties__evictions) do
      add :file_date, :date, null: false
      add :court_date, :date
      add :notes, :text
      add :lease_id, references(:properties__leases, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:properties__evictions, [:lease_id])
  end
end
