defmodule AppCount.Repo.Migrations.CreateAdminsActions do
  use Ecto.Migration

  def change do
    create table(:admins__actions) do
      add :ip, :string, null: false
      add :description, :string, null: false
      add :params, :jsonb, null: false
      add :admin_id, references(:admins__admins, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:admins__actions, [:admin_id])
  end
end
