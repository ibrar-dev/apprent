defmodule AppCount.Repo.Migrations.CreateMaintenancePaidTime do
  use Ecto.Migration

  def change do
    create table(:maintenance__paid_time) do
      add :hours, :integer, null: false
      add :date, :date, null: true
      add :approved, :boolean, default: false, null: true
      add :reason, :string, null: true
      add :tech_id, references(:maintenance__techs, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:maintenance__paid_time, [:tech_id])
  end
end
