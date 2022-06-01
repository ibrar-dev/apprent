defmodule AppCount.Repo.Migrations.AlterStockAndMaterialToUseJoinTable do
  use Ecto.Migration


  def change do
    alter table(:materials__materials) do
      remove :stock_id
    end
  end
end
