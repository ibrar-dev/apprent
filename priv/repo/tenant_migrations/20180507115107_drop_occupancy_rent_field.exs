defmodule AppCount.Repo.Migrations.DropOccupancyRentField do
  use Ecto.Migration

  def change do
    alter table(:properties__occupancies) do
      remove :rent
    end
  end
end
