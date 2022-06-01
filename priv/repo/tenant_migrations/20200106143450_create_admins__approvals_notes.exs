defmodule AppCount.Repo.Migrations.CreateAdminsApprovalsNotes do
  use Ecto.Migration

  def change do
    create table(:admins__approvals_notes) do
      add :admin_id, references(:admins__admins, on_delete: :delete_all), null: false
      add :approval_id, references(:admins__approvals, on_delete: :delete_all), null: false
      add :note, :string, null: false

      timestamps()
    end
    create index(:admins__approvals_notes, [:admin_id])
    create index(:admins__approvals_notes, [:approval_id])
  end
end
