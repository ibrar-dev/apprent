defmodule AppCount.Repo.Migrations.CreateFirstPropertiesOccupancies do
  use Ecto.Migration

  def change do
    create table(:properties__occupancies) do
      add :start_date, :utc_datetime, null: false
      add :end_date, :utc_datetime, null: false
      add :termination, :string
      add :rent, :decimal, null: false
      add :notes, :text
      add :tenant_id, references(:properties__tenants, on_delete: :delete_all), null: false
      add :unit_id, references(:properties__units, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:properties__occupancies, [:tenant_id])
    create index(:properties__occupancies, [:unit_id])
  end
end
