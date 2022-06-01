defmodule AppCount.Repo.Migrations.CreateExportsRecipients do
  use Ecto.Migration

  def change do
    create table(:exports__recipients) do
      add :name, :string, null: false
      add :email, :string, null: false
      add :admin_id, references(:admins__admins, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:exports__recipients, [:admin_id])
  end
end
