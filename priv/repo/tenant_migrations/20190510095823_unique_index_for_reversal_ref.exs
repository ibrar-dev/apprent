defmodule AppCount.Repo.Migrations.UniqueIndexForReversalRef do
  use Ecto.Migration

  def change do
    drop_if_exists index(:accounting__charges, [:reversal_id])
    drop_if_exists index(:accounting_charges, [:reversal_id])
    create unique_index(:accounting__charges, [:reversal_id])
  end
end
