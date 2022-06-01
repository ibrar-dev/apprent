defmodule AppCount.Repo.Migrations.MvEntityToRegion do
  use Ecto.Migration

  def change do
    rename table(:admins__entities), to: table(:admins__regions)
    rename table(:properties__scopings), :entity_id, to: :region_id
    rename table(:admins__permissions), :entity_id, to: :region_id
  end
end
