defmodule AppCount.Repo.Migrations.RemoveTenantConstraints do
  use Ecto.Migration

  def change do
    drop constraint(:tenants__tenancies, :non_future_move_out)
    drop constraint(:tenants__tenancies, :non_future_move_in)
  end
end
