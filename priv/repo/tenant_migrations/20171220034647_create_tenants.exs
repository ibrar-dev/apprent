defmodule AppCount.Repo.Migrations.CreateTenants do
  use Ecto.Migration

  def change do
    create table(:properties__tenants) do
      add :email, :string
      add :first_name, :string, null: false
      add :last_name, :string, null: false
      add :payment_status, :string, null: false, default: "approved"
      add :residency_status, :string, null: false, default: "current"
      add :unit_id, references(:properties__units, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:properties__tenants, [:unit_id])
  end
end
