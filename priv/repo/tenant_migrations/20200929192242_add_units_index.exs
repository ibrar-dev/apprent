defmodule AppCount.Repo.Migrations.AddUnitsIndex do
  use Ecto.Migration

  def change do
    create index("properties__units", [:property_id])
  end
end
