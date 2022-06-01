defmodule AppCount.Repo.Migrations.CreateAdminsAlerts do
  use Ecto.Migration

  def change do
    create table(:admins__alerts) do
      add :note, :string, null: false
      add :sender, :string, default: "AppRent", null: false
      add :read, :boolean, default: false, null: false
      add :flag, :integer, default: 1, null: false
      add :history, :jsonb, null: false
      add :admin_id, references(:admins__admins, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:admins__alerts, [:admin_id])
  end
end
