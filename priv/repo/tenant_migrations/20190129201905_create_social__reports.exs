defmodule AppCount.Repo.Migrations.CreateSocialReports do
  use Ecto.Migration

  def change do
    create table(:social__reports) do
      add :admin_id, references(:admins__admins, on_delete: :delete_all)
      add :tenant_id, references(:properties__tenants, on_delete: :delete_all)
      add :post_id, references(:social__posts, on_delete: :delete_all)
      add :reason, :string, default: false

      timestamps()
    end

  end
end
