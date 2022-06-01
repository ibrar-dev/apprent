defmodule AppCount.Repo.Migrations.CreateJobsTasks do
  use Ecto.Migration

  def change do
    create table(:jobs__tasks) do
      add :description, :string, null: false
      add :arguments, :jsonb, default: "[]", null: false
      add :error, :text
      add :logs, {:array, :string}, default: "{}", null: false
      add :success, :boolean, default: false, null: false
      add :attempt_number, :integer, default: 1
      add :start_time, :naive_datetime
      add :end_time, :naive_datetime

      timestamps()
    end

  end
end
