defmodule AppCount.Repo.Migrations.AddMaxToRewardTypes do
  use Ecto.Migration

  def change do
    alter table(:rewards__types) do
      add :monthly_max, :integer, default: 1, null: false
    end
  end
end
