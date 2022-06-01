defmodule AppCount.Repo.Migrations.AddsMissingIndicies do
  use Ecto.Migration

  def change do
    create index(:accounting__batches, [:property_id])
  end
end
