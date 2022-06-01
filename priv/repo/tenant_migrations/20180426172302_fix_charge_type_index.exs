defmodule AppCount.Repo.Migrations.FixChargeTypeIndex do
  use Ecto.Migration

  def change do
    drop unique_index(:accounting__charge_types, [:description])
  end
end
