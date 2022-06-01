defmodule AppCount.Repo.Migrations.AddDailyAdditionToPropertySettings do
  use Ecto.Migration

  def change do
    alter table(:properties__settings) do
      add :daily_late_fee_addition, :decimal, default: 0, null: false
    end
  end
end
