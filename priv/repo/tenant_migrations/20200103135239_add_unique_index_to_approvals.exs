defmodule AppCount.Repo.Migrations.AddUniqueIndexToApprovals do
  use Ecto.Migration

  def change do
    create unique_index(:admins__approvals, [:num, :type])
  end
end
