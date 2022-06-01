defmodule AppCount.Repo.Migrations.CreateAdminsMessages do
  use Ecto.Migration

  def change do
    create table(:admins__messages) do
      add :content, :text, null: false
      add :category, :string, null: false
      add :admin_id, references(:admins__admins, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:admins__messages, [:admin_id])
  end
end
