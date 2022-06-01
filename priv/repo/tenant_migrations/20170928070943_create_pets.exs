defmodule RentApply.Repo.Migrations.CreatePets do
  use Ecto.Migration

  def change do
    create table(:rent_apply__pets) do
      add :type, :string, null: false
      add :breed, :string, null: false
      add :weight, :string, null: false
      add :name, :string, null: false
      add :application_id, references(:rent_apply__rent_applications, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:rent_apply__pets, [:application_id])
  end
end
