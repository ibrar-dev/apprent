defmodule AppCount.Repo.Migrations.RenameHoursToWebsite do
  use Ecto.Migration

  def change do
    alter table(:properties__properties) do
      remove :hours
      add :website, :string, null: true
    end
  end
end