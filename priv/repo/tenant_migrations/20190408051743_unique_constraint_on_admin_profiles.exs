defmodule AppCount.Repo.Migrations.UniqueConstraintOnAdminProfiles do
  use Ecto.Migration

  def change do
    create unique_index(:admins__profiles, [:admin_id])
  end
end
