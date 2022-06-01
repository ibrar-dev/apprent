defmodule AppCount.Repo.Migrations.ModifyAdminApprovalsNoteColumnType do
  use Ecto.Migration

  def change do
    alter table("admins__approvals_notes") do
      modify :note, :text, from: :string
    end
  end
end
