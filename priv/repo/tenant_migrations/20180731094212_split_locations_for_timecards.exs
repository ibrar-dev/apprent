defmodule AppCount.Repo.Migrations.SplitLocationsForTimecards do
  use Ecto.Migration

  def change do
    rename table(:maintenance__timecards), :location, to: :start_location

    alter table(:maintenance__timecards) do
      add :end_location, :jsonb
    end
  end
end
