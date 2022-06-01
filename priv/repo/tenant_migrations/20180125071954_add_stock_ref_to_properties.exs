defmodule AppCount.Repo.Migrations.AddStockRefToProperties do
  use Ecto.Migration

  def change do
    alter table(:properties__properties) do
      add :stock_id, references(:properties__properties, on_delete: :nilify_all)
    end

    create index(:properties__properties, [:stock_id])
  end
end
