defmodule AppCount.Repo.Migrations.AddSomeMissingIndexes do
  use Ecto.Migration

  def change do
    create index(:maintenance__assignments, [:admin_id])
    create index(:maintenance__parts, [:order_id])
  end
end
