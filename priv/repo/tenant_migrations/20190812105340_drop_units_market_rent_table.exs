defmodule AppCount.Repo.Migrations.DropUnitsMarketRentTable do
  use Ecto.Migration

  def change do
    drop table(:units__market_rent)
  end
end
