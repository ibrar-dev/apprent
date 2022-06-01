defmodule AppCount.Repo.Migrations.ShowingsTimestamps do
  use Ecto.Migration

  def change do
    alter table(:prospects__showings) do
      modify :date, :date
      add :start_time, :integer, null: false
      add :end_time, :integer, null: false
    end
  end
end
