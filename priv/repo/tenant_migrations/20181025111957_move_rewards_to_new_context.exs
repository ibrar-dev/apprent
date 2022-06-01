defmodule AppCount.Repo.Migrations.MoveRewardsToNewContext do
  use Ecto.Migration

  def change do
    rename table(:accounts__rewards), to: table(:rewards__awards)
    rename table(:accounts__reward_types), to: table(:rewards__types)
    rename table(:accounts__purchases), to: table(:rewards__purchases)
    rename table(:accounts__prizes), to: table(:rewards__prizes)
  end
end
