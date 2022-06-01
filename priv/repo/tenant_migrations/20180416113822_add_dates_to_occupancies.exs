defmodule AppCount.Repo.Migrations.AddDatesToOccupancies do
  use Ecto.Migration

  def change do
    alter table(:properties__occupancies) do
      add :expected_move_in, :date
      add :actual_move_in, :date
    end
  end
end
