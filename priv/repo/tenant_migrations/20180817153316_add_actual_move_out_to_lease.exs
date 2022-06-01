defmodule AppCount.Repo.Migrations.AddActualMoveOutToLease do
  use Ecto.Migration

  def change do
    alter table(:properties__leases) do
      add :actual_move_out, :date
    end
  end
end
