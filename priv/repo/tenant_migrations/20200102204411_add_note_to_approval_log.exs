defmodule AppCount.Repo.Migrations.AddNoteToApprovalLog do
  use Ecto.Migration

  def change do
    alter table(:admins__approval_logs) do
      add :notes, :string, null: true
    end
  end
end
