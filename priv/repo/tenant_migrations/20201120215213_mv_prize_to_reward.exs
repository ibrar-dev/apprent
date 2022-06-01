defmodule AppCount.Repo.Migrations.MvPrizeToReward do
  use Ecto.Migration

  def change do
    rename table(:rewards__prizes), to: table(:rewards__rewards)
    rename table(:rewards__purchases), :prize_id, to: :reward_id
  end

end
