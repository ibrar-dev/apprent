defmodule RentApply.Repo.Migrations.CreateEmergencyContacts do
  use Ecto.Migration

  def change do
    create table(:rent_apply__emergency_contacts) do
      add :name, :string, null: false
      add :relationship, :string, null: false
      add :phone, :string, null: false
      add :address, :string, null: false
      add :application_id, references(:rent_apply__rent_applications, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:rent_apply__emergency_contacts, [:application_id])
  end
end
