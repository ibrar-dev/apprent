defmodule AppCount.Repo.Migrations.CreateMaterials do
  use Ecto.Migration

  def change do
    create table(:maintenance__materials) do
      add :name, :string, null: false
      add :cost, :decimal, null: false, default: 0
      add :inventory, :integer, null: false, default: 0
      add :desired, :integer, null: false, default: 0
      add :stock_id, references(:maintenance__stocks, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:maintenance__materials, [:stock_id])
    create unique_index(:maintenance__materials, [:stock_id, :name])
  end
end
