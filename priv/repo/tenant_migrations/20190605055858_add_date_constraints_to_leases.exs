defmodule AppCount.Repo.Migrations.AddDateConstraintsToLeases do
  use Ecto.Migration

  def change do
    create constraint(:properties__leases, :non_future_move_out, check: "actual_move_out <= now()")
    create constraint(:properties__leases, :non_future_move_in, check: "actual_move_in <= now()")
  end
end
