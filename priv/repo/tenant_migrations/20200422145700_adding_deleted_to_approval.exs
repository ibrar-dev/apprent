defmodule AppCount.Repo.Migrations.AddingDeletedToApproval do
  use Ecto.Migration

  def change do
    alter table(:admins__approval_logs) do
      add :deleted, :boolean, default: false
    end
  end
end
