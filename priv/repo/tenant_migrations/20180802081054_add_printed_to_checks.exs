defmodule AppCount.Repo.Migrations.AddPrintedToChecks do
  use Ecto.Migration

  def change do
    alter table(:accounting__checks) do
      add :printed, :boolean, default: false, null: false
    end
  end
end
