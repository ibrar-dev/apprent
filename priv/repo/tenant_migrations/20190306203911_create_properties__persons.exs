defmodule AppCount.Repo.Migrations.CreatePropertiesPersons do
  use Ecto.Migration

  def change do
    create table(:properties__persons) do
      add :lease_id, references(:properties__leases, on_delete: :nothing), null: false
      add :first_name, :string, null: false
      add :middle_name, :string, null: true
      add :last_name, :string, null: false
      add :status, :string, null: false
      add :phone, :string, null: true
      add :email, :string, null: true

      timestamps()
    end

  end
end
