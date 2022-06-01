defmodule AppCount.Repo.Migrations.AddLookupIndexOnCardsForUnit do
  use Ecto.Migration

  def change do
    create index("maintenance__cards", [:unit_id])
  end
end
