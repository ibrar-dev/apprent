defmodule AppCount.Repo.Migrations.AddPointsToRewardsTypes do
  use Ecto.Migration

  def change do
    alter table(:rewards__types) do
      add :points, :integer, default: 0, null: false
      add :active, :boolean, default: true, null: false
    end

    create unique_index(:rewards__types, [:name])
  end
end
