defmodule AppCount.Repo.Migrations.UniqueUUIDs do
  use Ecto.Migration

  def change do
    create unique_index(:properties__units, :uuid)
    create unique_index(:properties__tenants, :uuid)
    create unique_index(:maintenance__orders, :uuid)
  end
end
