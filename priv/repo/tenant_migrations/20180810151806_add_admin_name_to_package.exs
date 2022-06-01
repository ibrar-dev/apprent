defmodule AppCount.Repo.Migrations.AddAdminNameToPackage do
  use Ecto.Migration

  def change do
    alter table(:properties__packages) do
      add :admin, :string, null: false
      add :notes, :string, null: true
    end
  end
end
