defmodule AppCount.Repo.Migrations.CreateJobsJobs do
  use Ecto.Migration

  def change do
    create table(:jobs__jobs) do
      add :schedule, :json, null: false, default: "{}"
      add :module, :string, null: false
      add :function, :string, null: false
      add :last_run, :integer
      add :next_run, :integer
      add :arguments, :json, null: false, default: "[]"

      timestamps()
    end

    Enum.each([:year, :month, :day, :hour, :minute, :week, :wday], fn(field)->
      create constraint(:jobs__jobs, :"#{field}_invalid", check: "schedule ->> '#{field}' != '[]'")
    end)

    create constraint(:jobs__jobs, :day_conflict, check: "schedule ->> 'day' IS NULL OR (schedule ->> 'wday' IS NULL AND schedule ->> 'week' IS NULL)")
  end
end
