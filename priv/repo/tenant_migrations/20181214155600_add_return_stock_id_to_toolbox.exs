defmodule AppCount.Repo.Migrations.AddReturnStockIdToToolbox do
  use Ecto.Migration

  def change do
    alter table(:materials__toolbox_items) do
      add :return_stock, :bigint, null: true
    end
  end
end
