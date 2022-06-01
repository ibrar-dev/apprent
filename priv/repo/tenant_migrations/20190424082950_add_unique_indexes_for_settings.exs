defmodule AppCount.Repo.Migrations.AddUniqueIndexesForSettings do
  use Ecto.Migration

  def change do
    create unique_index(:settings__damages, [:name])
    create unique_index(:settings__move_out_reasons, [:name])
    create unique_index(:settings__banks, [:routing])
  end
end
