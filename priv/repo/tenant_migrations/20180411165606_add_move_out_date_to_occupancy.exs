defmodule AppCount.Repo.Migrations.AddMoveOutDateToOccupancy do
  use Ecto.Migration

  def change do
    alter table(:properties__occupancies) do
      add :move_out_date, :date
      modify :start_date, :date
      modify :end_date, :date
    end
  end
end
