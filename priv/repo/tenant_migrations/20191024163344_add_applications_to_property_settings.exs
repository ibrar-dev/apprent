defmodule AppCount.Repo.Migrations.AddApplicationsToPropertySettings do
  use Ecto.Migration

  def change do
    alter table(:properties__settings) do
      add :applications, :boolean, null: false, default: true
      add :tours, :boolean, null: false, default: true
    end
  end
end
