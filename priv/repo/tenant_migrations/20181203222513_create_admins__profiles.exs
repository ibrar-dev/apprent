defmodule AppCount.Repo.Migrations.CreateAdminsProfiles do
  use Ecto.Migration

  def change do
    create table(:admins__profiles) do
      add :bio, :text, null: true
      add :admin_id, references(:admins__admins, on_delete: :delete_all), null: false
      add :image, :string, null: true
      add :active, :boolean, default: false

      timestamps()
    end
  end
end
