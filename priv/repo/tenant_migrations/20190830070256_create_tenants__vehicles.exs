defmodule AppCount.Repo.Migrations.CreateTenantsVehicles do
  use Ecto.Migration

  def change do
    create table(:tenants__vehicles) do
      add :make_model, :string, null: false
      add :color, :string, null: false
      add :license_plate, :string, null: false
      add :state, :string, null: false
      add :tenant_id, references(:tenants__tenants, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:tenants__vehicles, [:tenant_id])
  end
end
