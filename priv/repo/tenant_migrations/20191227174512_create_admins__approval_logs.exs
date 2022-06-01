defmodule AppCount.Repo.Migrations.CreateAdminsApprovalLogs do
  use Ecto.Migration

  def change do
    create table(:admins__approval_logs) do
      add :admin_id, references(:admins__admins, on_delete: :nilify_all), null: false
      add :approval_id, references(:admins__approvals, on_delete: :delete_all), null: false
      add :status, :string, null: false

      timestamps()
    end
    create index(:admins__approval_logs, [:admin_id])
    create index(:admins__approval_logs, [:approval_id])
  end
end
