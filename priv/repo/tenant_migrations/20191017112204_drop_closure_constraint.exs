defmodule AppCount.Repo.Migrations.DropClosureConstraint do
  use Ecto.Migration

  def change do
    drop constraint(:prospects__closures, :closure_date_not_in_past)
  end
end
