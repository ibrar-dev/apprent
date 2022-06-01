defmodule AppCount.Repo.Migrations.CreateAdminsApprovalAttachments do
  use Ecto.Migration

  def change do
    create table(:admins__approval_attachments) do
      add :approval_id, references(:admins__approvals, on_delete: :delete_all), null: false
      add :attachment_id, references(:data__uploads, on_delete: :nilify_all), null: false

      timestamps()
    end

  end
end
