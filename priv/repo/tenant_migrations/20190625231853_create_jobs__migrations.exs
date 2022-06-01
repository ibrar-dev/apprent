defmodule AppCount.Repo.Migrations.CreateJobsMigrations do
  use Ecto.Migration

  def change do
    create table(:jobs__migrations) do
      add :module, :string, null: false
      add :function, :string, null: false
      add :arguments, :jsonb, null: false, default: "{}"

      timestamps()
    end

  end
end
