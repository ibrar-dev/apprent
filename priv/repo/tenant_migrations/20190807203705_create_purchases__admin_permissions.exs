defmodule AppCount.Repo.Migrations.CreatePurchasesAdminPermissions do
  use Ecto.Migration

  def change do
    create table(:purchases__admin_permissions) do
      add :admin_id, references(:admins__admins)
      add :property_id, references(:properties__properties)
      add :presence_status, :string, defualt: 'available'
      add :path, {:array, :integer}, null: false, default: "{}"
      add :title, :string, null: false

      timestamps()
    end

  end
end
