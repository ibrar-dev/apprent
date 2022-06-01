defmodule AppCount.Repo.Migrations.CreateAdminsApprovals do
  use Ecto.Migration

  def change do
    create table(:admins__approvals) do
      add :admin_id, references(:admins__admins, on_delete: :nilify_all), null: false
      add :property_id, references(:properties__properties, on_delete: :delete_all), null: false
      add :notes, :string, null: true
      add :type, :string, null: false
      add :params, :jsonb, null: false
      add :num, :string, null: false

      timestamps()
    end

    create index(:admins__approvals, [:admin_id])
    create index(:admins__approvals, [:property_id])
  end
end
