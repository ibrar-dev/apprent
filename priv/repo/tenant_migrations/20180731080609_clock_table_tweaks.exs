defmodule AppCount.Repo.Migrations.ClockTableTweaks do
  use Ecto.Migration

  def change do
    rename table(:maintenance__clocks), to: table(:maintenance__timecards)

    alter table(:maintenance__timecards) do
      remove :time
      remove :status
      add :start_ts, :bigint, null: false
      add :end_ts, :bigint
    end

    create index(:maintenance__timecards, [:tech_id])
  end
end
