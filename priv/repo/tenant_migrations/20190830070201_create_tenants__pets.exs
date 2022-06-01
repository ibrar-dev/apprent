defmodule AppCount.Repo.Migrations.CreateTenantsPets do
  use Ecto.Migration

  def change do
    create table(:tenants__pets) do
      add :type, :string, null: false
      add :breed, :string, null: false
      add :weight, :string, null: false
      add :name, :string, null: false
      add :tenant_id, references(:tenants__tenants, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:tenants__pets, [:tenant_id])
  end
end
