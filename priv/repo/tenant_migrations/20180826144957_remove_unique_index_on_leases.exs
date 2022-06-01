defmodule AppCount.Repo.Migrations.RemoveUniqueIndexOnLeases do
  use Ecto.Migration

  def change do
    drop unique_index(:properties__charges, [:lease_id, :account_id])
  end
end
