defmodule RentApply.Repo.Migrations.CreateVehicles do
  use Ecto.Migration

  def change do
    create table(:rent_apply__vehicles) do
      add :make_model, :string, null: false
      add :color, :string, null: false
      add :license_plate, :string, null: false
      add :state, :string, null: false
      add :application_id, references(:rent_apply__rent_applications, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:rent_apply__vehicles, [:application_id])
  end
end
