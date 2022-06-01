defmodule AppCount.Repo.Migrations.AddClearedToChecks do
  use Ecto.Migration

  def change do
    alter table(:accounting__checks) do
      add :cleared, :boolean, null: false, default: false
    end
  end
end
