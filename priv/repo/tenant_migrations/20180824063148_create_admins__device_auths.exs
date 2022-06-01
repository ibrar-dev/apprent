defmodule AppCount.Repo.Migrations.CreateAdminsDeviceAuths do
  use Ecto.Migration

  def change do
    create table(:admins__device_auths) do
      add :device_id, references(:admins__devices, on_delete: :delete_all), null: false
      add :property_id, references(:properties__properties, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:admins__device_auths, [:device_id, :property_id])
  end
end
