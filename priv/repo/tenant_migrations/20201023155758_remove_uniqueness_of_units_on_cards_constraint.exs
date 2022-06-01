defmodule AppCount.Repo.Migrations.RemoveUniquenessOfUnitsOnCardsConstraint do
  use Ecto.Migration

  def change do
    drop index("maintenance__cards", [:unit_id])
  end
end
